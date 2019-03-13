module Api
  class SchoolCalendarStepActivity < BaseSchoolCalendarStepActivity
    def initialize(unity_id, calendar_step, step_number)
      @unity_id = unity_id
      @calendar_step = calendar_step
      @step_number = step_number
    end

    def any_activity?
      return true if frequencies_in_step(
        @calendar_step.school_calendar_id,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity_id(@unity_id).exists?

      return true if Avaliation.by_unity_id(@unity_id)
                               .by_school_calendar_step(@calendar_step.id)
                               .exists?

      return true if conceptual_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity(@unity_id).exists?

      return true if descriptive_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity_id(@unity_id).exists?

      false
    end
  end
end
