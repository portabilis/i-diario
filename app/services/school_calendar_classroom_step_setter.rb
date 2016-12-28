class SchoolCalendarClassroomStepSetter
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def set
    if has_params? && set_school_calendar_classroom_step
      success
    else
      error
    end
  end

  private

  def has_params?
    name
  end

  def set_school_calendar_classroom_step
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        # school_calendar_classrooms = SchoolCalendarClassroom.all
        # classroom_ids = []
        # school_calendar_classrooms.each do |school_calendar_classroom|
        #   school_name = school_calendar_classroom.school_calendar.unity.name
        #   school_steps = school_calendar_classroom.school_calendar.steps.count
        #   classroom_description = school_calendar_classroom.classroom.description
        #   classroom_steps = school_calendar_classroom.classroom_steps.count
        #   next if school_steps == classroom_steps
        #
        #   classroom_ids << school_calendar_classroom.classroom_id
        #   p "Escola: #{school_name} - Etapas: #{school_steps} / Turma: #{classroom_description} - Etapas: #{classroom_steps} - ID: #{school_calendar_classroom.classroom_id}"
        #   p "*****************************"
        # end
        #
        # p classroom_ids


        classroom_ids = SchoolCalendarClassroom.all.collect(&:classroom_id)

        conceptual_exams = ConceptualExam.where(classroom_id: classroom_ids)
        descriptive_exams = DescriptiveExam.where(classroom_id: classroom_ids).where.not(school_calendar_step_id: nil)
        transfer_notes = TransferNote.where(classroom_id: classroom_ids)
        school_term_recovery_diary_records = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_ids)

        conceptual_exams.each do |conceptual_exam|
          school_steps = conceptual_exam.school_calendar_step.school_calendar.steps
          classroom_steps = find_classroom_steps(conceptual_exam.classroom_id)
          if same_number_steps?(school_steps, classroom_steps)
            conceptual_exam.school_calendar_classroom_step_id = find_same_number_step(classroom_steps, conceptual_exam)
          else
            recorded_at = conceptual_exam.recorded_at
            conceptual_exam.school_calendar_classroom_step_id = classroom_steps.started_after_and_before(recorded_at).first.id
          end
          conceptual_exam.save(validate: false)
        end

        descriptive_exams.each do |descriptive_exam|
          school_steps = descriptive_exam.school_calendar_step.school_calendar.steps
          classroom_steps = find_classroom_steps(descriptive_exam.classroom_id)
          if same_number_steps?(school_steps, classroom_steps)
            descriptive_exam.school_calendar_classroom_step_id = find_same_number_step(classroom_steps, descriptive_exam)
          else
            created_at = descriptive_exam.created_at
            descriptive_exam.school_calendar_classroom_step_id = classroom_steps.started_after_and_before(created_at).first.id
          end
          descriptive_exam.save(validate: false)
        end

        transfer_notes.each do |transfer_note|
          school_steps = transfer_note.school_calendar_step.school_calendar.steps
          classroom_steps = find_classroom_steps(transfer_note.classroom_id)
          if same_number_steps?(school_steps, classroom_steps)
            transfer_note.school_calendar_classroom_step_id = find_same_number_step(classroom_steps, transfer_note)
          else
            transfer_date = transfer_note.transfer_date
            transfer_note.school_calendar_classroom_step_id = classroom_steps.started_after_and_before(created_at).first.id
          end
           transfer_note.save(validate: false)
        end

        school_term_recovery_diary_records.each do |school_term_recovery_diary_record|
          school_steps = school_term_recovery_diary_record.school_calendar_step.school_calendar.steps
          classroom_steps = find_classroom_steps(school_term_recovery_diary_record.recovery_diary_record.classroom_id)
          if same_number_steps?(school_steps, classroom_steps)
            school_term_recovery_diary_record.school_calendar_classroom_step_id = find_same_number_step(classroom_steps, school_term_recovery_diary_record)
          else
            recorded_at = school_term_recovery_diary_record.recovery_diary_record.recorded_at
            school_term_recovery_diary_record.school_calendar_classroom_step_id = classroom_steps.started_after_and_before(recorded_at).first.id
          end
           school_term_recovery_diary_record.save(validate: false)
        end
      end
    else
      false
    end
  end

  def same_number_steps?(school_steps, classroom_steps)
    school_steps.count == classroom_steps.count
  end

  def find_same_number_step(classroom_steps, record)
    classroom_steps.select { |step| step.to_number == record.school_calendar_step.to_number}.first.try(:id)
  end

  def find_classroom_steps(classroom_id)
    SchoolCalendarClassroomStep.joins(:school_calendar_classroom).where(school_calendar_classrooms: { classroom_id: classroom_id })
  end

  def success
    @status = I18n.t('services.school_calendar_classroom_step_setter.success')
  end

  def error
    @status = I18n.t('services.school_calendar_classroom_step_setter.error')
  end
end
