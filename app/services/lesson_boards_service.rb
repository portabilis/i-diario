class LessonBoardsService
  def teachers(classroom_id, period, grade_id)
    teachers_to_select2 = []
    classroom_period = Classroom.find(classroom_id).period

    allocations = TeacherDisciplineClassroom.where(classroom_id: classroom_id)
                                            .includes(:teacher, discipline: :knowledge_area)
                                            .where(disciplines: { descriptor: false })
                                            .where(grade_id: grade_id)
                                            .order('teachers.name')

    allocations.where(period: period) if classroom_period == Periods::FULL && period

    allocations.each do |teacher_discipline_classroom|
      teachers_to_select2 << OpenStruct.new(
        id: teacher_discipline_classroom.id,
        name: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                      teacher_discipline_classroom.teacher.name.try(:strip)),
        text: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                      teacher_discipline_classroom.teacher.name.try(:strip))
      )
    end

    teachers_to_select2.insert(0, OpenStruct.new(id: 'empty', name: '<option></option>', text: ''))
  end

  def linked_teacher(teacher_discipline_classroom_id, lesson_number, weekday, classroom, period)
    teacher_discipline_classroom = TeacherDisciplineClassroom.includes(:teacher, classroom: :unity)
                                                             .find(teacher_discipline_classroom_id)
    teacher_id = teacher_discipline_classroom.teacher.id
    year = teacher_discipline_classroom.classroom.year

    linked = LessonsBoardLessonWeekday.includes(teacher_discipline_classroom: [:teacher, classroom: :unity])
                                      .where(weekday: weekday)
                                      .joins(lessons_board_lesson: :lessons_board,
                                             teacher_discipline_classroom: [:teacher, classroom: :classrooms_grades])
                                      .where(teachers: { id: teacher_id })
                                      .where(classrooms: { year: year, period: period })
                                      .where(lessons_board_lessons: { lesson_number: lesson_number })
                                      .where.not(classrooms_grades: { classroom_id: classroom.to_i })
                                      .first

    return false if linked.nil?

    return false if end_period?(linked.teacher_discipline_classroom.classroom_id, classroom.to_i)

    linked_teacher_message_error(linked.teacher_discipline_classroom.teacher.name,
                                 linked.teacher_discipline_classroom.classroom.description,
                                 linked.teacher_discipline_classroom.classroom.unity,
                                 linked.teacher_discipline_classroom.classroom.year,
                                 Workdays.translate(Workdays.key_for(weekday.to_s)),
                                 lesson_number, teacher_discipline_classroom)
  end

  private

  def end_period?(linked_classroom_id, classroom_id)
    linked_school_calendar_classroom = SchoolCalendarClassroom.by_classroom(linked_classroom_id)

    return false if linked_school_calendar_classroom.blank?

    school_calendar_classroom = SchoolCalendarClassroom.by_classroom(classroom_id)

    return false if school_calendar_classroom.blank?

    last_day = SchoolCalendarClassroom.by_classroom(linked_classroom_id).last.last_day
    first_day = SchoolCalendarClassroom.by_classroom(classroom_id).last.first_day

    last_day < first_day
  end

  def discipline_teacher_name(discipline, teacher)
    "<div class='flex-between'>
       <div class='flex-teacher'>
          <div>
            #{teacher.upcase}
          </div>
       </div>
       <div class='flex-discipline'>
         <span class='flex-discipline-span' style='background-color: #{discipline.label_color};'>
           #{discipline.description.try(:strip)}
         </span>
       </div>
     </div>"
  end

  def linked_teacher_message_error(name, classroom, unity, year, weekday, lesson_number, other_allocation)
    if other_allocation.classroom.unity.id.eql?(unity.id)
      OpenStruct.new(message: "O(a) professor(a) #{name} já está alocado(a) para a turma #{classroom} na mesma escola
      em #{year} na #{weekday} e na #{lesson_number}ª aula. Para conseguir vincular o mesmo, efetue a troca de
      horário em uma das turmas.")
    else
      OpenStruct.new(message: "O(a) professor(a) #{name} já está alocado(a) para a turma #{classroom} na #{unity.name}
      em #{year} na #{weekday} e na #{lesson_number}ª aula. Para conseguir vincular o mesmo, favor contatar o(a)
      responsável da escola para efetuar a troca de horário.")
    end
  end
end
