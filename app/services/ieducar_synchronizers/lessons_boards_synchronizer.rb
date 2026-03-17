class LessonsBoardsSynchronizer < BaseSynchronizer
  def synchronize!
    unity_api_code.to_s.split(',').each do |school_id|
      update_lessons_boards(
        HashDecorator.new(
          api.fetch(
            year: year,
            school_id: school_id
          )['data']
        )
      )
    end
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::LessonsBoards
  end

  def update_lessons_boards(records)
    day_names = %w[sunday monday tuesday wednesday thursday friday saturday]

    preload_classrooms(records.map { |r| r.id.to_s })
    preload_grades(records.map { |r| r.grade_id.to_s })

    classroom_ids = records.map { |r| classroom(r.id.to_s)&.id }.compact
    grade_ids     = records.map { |r| grade(r.grade_id.to_s)&.id }.compact

    # Passo 1: ClassroomsGrade indexado por [classroom_id, grade_id]
    classrooms_grade_index = ClassroomsGrade.with_discarded
      .where(classroom_id: classroom_ids, grade_id: grade_ids)
      .index_by { |cg| [cg.classroom_id, cg.grade_id] }

    # Passo 2: LessonsBoard indexado por [classrooms_grade_id, period]
    lessons_board_index = LessonsBoard.with_discarded
      .where(classrooms_grade_id: classrooms_grade_index.values.map(&:id))
      .group_by(&:classrooms_grade_id)
      .transform_values { |lbs| lbs.index_by(&:period) }

    # Passo 3: TeacherDisciplineClassroom indexado por [classroom_api_code, teacher_api_code, discipline_api_code]
    tdc_index = TeacherDisciplineClassroom.unscoped
      .where(classroom_api_code: records.map { |r| r.id.to_s }.uniq, year: year)
      .index_by { |t| [t.classroom_api_code, t.teacher_api_code, t.discipline_api_code] }

    ActiveRecord::Base.transaction do
      # Passo 4: Resolve LessonsBoard e separa os que têm timetable
      records_with_board       = []
      boards_with_empty_slots  = []

      records.each do |record|
        classroom = classroom(record.id.to_s)
        grade     = grade(record.grade_id.to_s)
        next if classroom.blank? || grade.blank?

        classrooms_grade = classrooms_grade_index[[classroom.id, grade.id]]
        next if classrooms_grade.blank?

        lessons_board = lessons_board_index.dig(classrooms_grade.id, record.shift_id) ||
                        LessonsBoard.new(classrooms_grade_id: classrooms_grade.id, period: record.shift_id)

        # Descarta quando não há um quadro de horários publicado
        if record.timetable.blank?
          lessons_board.discard unless lessons_board.new_record? || lessons_board.discarded?
          next
        end

        lessons_board.undiscard if lessons_board.persisted? && lessons_board.discarded?
        lessons_board.save! if lessons_board.new_record? || lessons_board.changed?

        # Timetable existe mas sem slots: limpa lessons e weekdays do board
        if record.timetable.slots.blank?
          boards_with_empty_slots << lessons_board
          next
        end

        records_with_board << { record: record, lessons_board: lessons_board }
      end

      # Passo 5: LessonsBoardLesson indexado por [lessons_board_id, lesson_number]
      lessons_board_ids = records_with_board.map { |d| d[:lessons_board].id } +
                          boards_with_empty_slots.map(&:id)
      lessons_index = LessonsBoardLesson.with_discarded
        .where(lessons_board_id: lessons_board_ids)
        .group_by(&:lessons_board_id)
        .transform_values { |ls| ls.index_by(&:lesson_number) }

      # Salva novos LessonsBoardLesson para obter IDs antes do bulk load de weekdays
      records_with_board.each do |data|
        data[:record].timetable.slots.group_by(&:shift_period_id).keys.sort_by(&:to_i).each do |shift_period_id|
          lesson_number = shift_period_id.to_s
          next if lessons_index.dig(data[:lessons_board].id, lesson_number)

          lesson = LessonsBoardLesson.new(
            lessons_board_id: data[:lessons_board].id,
            lesson_number: lesson_number
          )
          lesson.save!
          (lessons_index[data[:lessons_board].id] ||= {})[lesson_number] = lesson
        end
      end

      # Passo 6: LessonsBoardLessonWeekday indexado por [lessons_board_lesson_id, weekday]
      all_lesson_ids = lessons_index.values.flat_map { |h| h.values.map(&:id) }
      weekdays_index = LessonsBoardLessonWeekday.with_discarded
        .where(lessons_board_lesson_id: all_lesson_ids)
        .group_by(&:lessons_board_lesson_id)
        .transform_values { |wds| wds.index_by(&:weekday) }

      # Descarta todos os LessonsBoardLesson e LessonsBoardLessonWeekday de boards sem slots
      boards_with_empty_slots.each do |lessons_board|
        (lessons_index[lessons_board.id] || {}).each_value do |lesson|
          (weekdays_index[lesson.id] || {}).each_value do |weekday|
            weekday.discard unless weekday.discarded?
          end
          lesson.discard unless lesson.discarded?
        end
      end

      # Passo 7: Processa slots inteiramente em memória
      records_with_board.each do |data|
        record        = data[:record]
        lessons_board = data[:lessons_board]

        record.timetable.slots.group_by(&:shift_period_id).each do |shift_period_id, slots|
          lesson = lessons_index.dig(lessons_board.id, shift_period_id.to_s)
          next if lesson.blank?

          lesson.undiscard if lesson.persisted? && lesson.discarded?
          lesson.save! if lesson.changed?

          expected_weekday_names = slots.map { |slot| day_names[slot.day_of_week_id] }.compact

          slots.each do |slot|
            tdc = tdc_index[[record.id.to_s, slot.teacher_id.to_s, slot.subject_id.to_s]]
            next if tdc.blank?

            weekday_name = day_names[slot.day_of_week_id]
            weekday = weekdays_index.dig(lesson.id, weekday_name) ||
                      LessonsBoardLessonWeekday.new(lessons_board_lesson_id: lesson.id, weekday: weekday_name)
            weekday.undiscard if weekday.persisted? && weekday.discarded?
            weekday.teacher_discipline_classroom_id = tdc.id
            weekday.save! if weekday.new_record? || weekday.changed?
          end

          # Descarta weekdays que não estão mais presentes nos slots da API
          (weekdays_index[lesson.id] || {}).each do |weekday_name, weekday|
            next if expected_weekday_names.include?(weekday_name)
            next if weekday.discarded?

            weekday.discard
          end
        end
      end
    end
  end
end
