class ConceptualExamsSchoolCalendarStepUpdater
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def update
    if has_params? && update_conceptual_exams_school_calendar_step
      success
    else
      error
    end
  end

  private

  def has_params?
    name
  end

  def update_conceptual_exams_school_calendar_step
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        conceptual_exams = ConceptualExam.all
        conceptual_exams.each do |conceptual_exam|
          if conceptual_exam.school_calendar_step.nil?
            conceptual_exam.destroy
            next
          end

          next if conceptual_exam.school_calendar_step.school_calendar.unity_id

          old_school_calendar = SchoolCalendar.find_by(id: conceptual_exam.school_calendar_step.school_calendar.id)
          new_school_calendar = SchoolCalendar.find_by(unity_id: conceptual_exam.classroom.unity_id, year: conceptual_exam.school_calendar_step.start_at.year)

          index_of_old_step = old_school_calendar.steps.find_index(conceptual_exam.school_calendar_step)
          new_step = new_school_calendar.steps[index_of_old_step]

          if new_step
            existing_conceptual_exam = ConceptualExam.find_by(classroom_id: conceptual_exam.classroom_id, school_calendar_step_id: new_step.id)
            if existing_conceptual_exam
              if existing_conceptual_exam.students.any? { |student| student.value.present? }
                conceptual_exam.destroy
                next
              end

              existing_conceptual_exam.destroy
            end

            conceptual_exam.school_calendar_step = new_school_calendar.steps[index_of_old_step]
            conceptual_exam.save(validate: false)
          end
        end
      end
    else
      false
    end
  end

  def success
    @status = I18n.t('services.conceptual_exams_school_calendar_step_updater.success')
  end

  def error
    @status = I18n.t('services.conceptual_exams_school_calendar_step_updater.error')
  end
end
