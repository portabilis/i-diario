class DescriptiveExamsSchoolCalendarStepUpdater
  attr_reader :name,
              :status

  def initialize(options)
    @name = options["NAME"]
  end

  def update
    if has_params? && update_descriptive_exams_school_calendar_step
      success
    else
      error
    end
  end

  private

  def has_params?
    name
  end

  def update_descriptive_exams_school_calendar_step
    entity = Entity.find_by_name(name)
    if entity
      entity.using_connection do
        descriptive_exams = DescriptiveExam.all
        descriptive_exams.each do |descriptive_exam|
          if descriptive_exam.school_calendar_step.nil?
            descriptive_exam.destroy
            next
          end

          next if descriptive_exam.school_calendar_step.school_calendar.unity_id

          old_school_calendar = SchoolCalendar.find_by(id: descriptive_exam.school_calendar_step.school_calendar.id)
          new_school_calendar = SchoolCalendar.find_by(unity_id: descriptive_exam.classroom.unity_id, year: descriptive_exam.school_calendar_step.start_at.year)

          index_of_old_step = old_school_calendar.steps.find_index(descriptive_exam.school_calendar_step)
          new_step = new_school_calendar.steps[index_of_old_step]

          if new_step
            existing_descriptive_exam = DescriptiveExam.find_by(classroom_id: descriptive_exam.classroom_id, school_calendar_step_id: new_step.id)
            if existing_descriptive_exam
              if existing_descriptive_exam.students.any? { |student| student.value.present? }
                descriptive_exam.destroy
                next
              end

              existing_descriptive_exam.destroy
            end

            descriptive_exam.school_calendar_step = new_school_calendar.steps[index_of_old_step]
            descriptive_exam.save(validate: false)
          end
        end
      end
    else
      false
    end
  end

  def success
    @status = I18n.t('services.descriptive_exams_school_calendar_step_updater.success')
  end

  def error
    @status = I18n.t('services.descriptive_exams_school_calendar_step_updater.error')
  end
end
