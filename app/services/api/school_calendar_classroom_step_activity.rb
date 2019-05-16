module Api
  class SchoolCalendarClassroomStepActivity < BaseSchoolCalendarStepActivity
    def initialize(classroom, step_number)
      @classroom = classroom
      @calendar_step = school_classroom_calendar_step(step_number)
      @step_number = step_number
    end

    def any_activity?
      raise ActiveRecord::RecordNotFound if @calendar_step.nil?

      return true if frequencies_in_step(
        @calendar_step.school_calendar_id,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom.id).exists?

      return true if Avaliation.by_classroom_id(@classroom.id)
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
      ).by_classroom_id(@classroom.id).exists?

      return true if recoveries_in_step(
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom.id).exists?

      return true if transfer_notes_in_step(
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom.id).exists?

      return true if complementary_exams_in_step(
        @step_number,
        @calendar_step.start_at,
        @calendar_step.end_at
      ).by_classroom_id(@classroom.id).exists?

      false
    end

    private

    def school_classroom_calendar_step(step_number)
      StepsFetcher.new(@classroom).step(step_number)
    end
  end
end
