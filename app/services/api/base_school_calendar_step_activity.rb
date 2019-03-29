class BaseSchoolCalendarStepActivity
  private

  def frequencies_in_step(school_calendar_id, start_at, end_at)
    DailyFrequency.by_school_calendar_id(school_calendar_id)
                  .by_frequency_date_between(start_at, end_at)
  end

  def conceptual_exams_in_step(step_number, start_at, end_at)
    ConceptualExam.by_recorded_at_between(start_at, end_at)
                  .where(step_number: step_number)
  end

  def descriptive_exams_in_step(step_number, start_at, end_at)
    DescriptiveExam.by_recorded_at_between(start_at, end_at)
                   .where(step_number: step_number)
  end
end
