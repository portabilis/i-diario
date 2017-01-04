class SchoolCalendarClassroomStepSetterByStep
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
        classroom_ids = SchoolCalendarClassroom.all.collect(&:classroom_id)

        conceptual_exams = ConceptualExam.where(classroom_id: classroom_ids)
        descriptive_exams = DescriptiveExam.where(classroom_id: classroom_ids).where.not(school_calendar_step_id: nil)
        transfer_notes = TransferNote.where(classroom_id: classroom_ids)
        school_term_recovery_diary_records = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom_ids)

        conceptual_exams.each do |conceptual_exam|
          next unless conceptual_exam.school_calendar_step_id

          school_calendar_classroom_steps = find_classroom_steps(conceptual_exam.classroom_id)
          conceptual_exam.school_calendar_classroom_step_id = find_same_number_step(school_calendar_classroom_steps, conceptual_exam)
        end

        descriptive_exams.each do |descriptive_exam|
          next unless descriptive_exam.school_calendar_step_id

          school_calendar_classroom_steps = find_classroom_steps(descriptive_exam.classroom_id)
          descriptive_exam.school_calendar_classroom_step_id = find_same_number_step(school_calendar_classroom_steps, descriptive_exam)
        end
        
        transfer_notes.each do |transfer_note|
          next unless transfer_note.school_calendar_step_id

          school_calendar_classroom_steps = find_classroom_steps(transfer_note.classroom_id)
          transfer_note.school_calendar_classroom_step_id = find_same_number_step(school_calendar_classroom_steps, transfer_note)
        end

        school_term_recovery_diary_records.each do |school_term_recovery_diary_record|
          next unless school_term_recovery_diary_record.school_calendar_step_id

          school_calendar_classroom_steps = find_classroom_steps(school_term_recovery_diary_record.recovery_diary_record.classroom_id)
          school_term_recovery_diary_record.school_calendar_classroom_step_id = find_same_number_step(school_calendar_classroom_steps, school_term_recovery_diary_record)
        end
      end

    else
      false
    end
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
