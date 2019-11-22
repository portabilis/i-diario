module Api
  class SchoolCalendarStepActivity < BaseSchoolCalendarStepActivity
    def initialize(unity_id, year, step_number)
      @unity_id = unity_id
      @calendar_step = school_calendar_step(unity_id, year, step_number)
      @step_number = step_number
    end

    def any_activity?
      raise ActiveRecord::RecordNotFound if @calendar_step.nil?

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

      return true if recoveries_in_step(
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity_id(@unity_id).exists?

      return true if transfer_notes_in_step(
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity_id(@unity_id).exists?

      return true if complementary_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_unity_id(@unity_id).exists?

      false
    end

    private

    def school_calendar_step(unity_id, year, step_number)
      SchoolCalendarStep.by_unity(unity_id)
                        .by_year(year)
                        .by_step_number(step_number)
                        .first
    end
  end
end
