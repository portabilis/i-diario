module Api
  class SchoolCalendarClassroomStepActivity < BaseSchoolCalendarStepActivity
    def initialize(classroom_id, step_number)
      @classroom_id = classroom_id
      @calendar_step = school_classroom_calendar_step(step_number)
      @step_number = step_number
    end

    def any_activity?
      return true if frequencies_in_step(
        @calendar_step.school_calendar_id,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom_id).exists?

      return true if Avaliation.by_classroom_id(@classroom_id)
                               .by_school_calendar_classroom_step(@calendar_step.id)
                               .exists?

      return true if conceptual_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom(@classroom).exists?

      return true if descriptive_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom_id).exists?

      false
    end

    private

    def school_classroom_calendar_step(step_number)
      StepsFetcher.new(@classroom).step(step_number)
    end
  end
end
