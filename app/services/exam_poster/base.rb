module ExamPoster
  class Base
    class InvalidClassroomError < StandardError; end

    attr_accessor :warning_messages

    def initialize(post_data)
      @post_data = post_data
      @warning_messages = []
    end

    def post!
      raise NotImplementedError
    end

    def step_exists_for_classroom?(classroom)
      return false if invalid_classroom_year?(classroom)

      classroom.calendar.blank? || classroom.calendar.classroom_steps.any? do |classroom_step|
        classroom_step.to_number == @post_data.step.to_number
      end
    end

    def has_classroom_steps(classroom)
      classroom.calendar
    end

    def get_step(classroom)
      raise InvalidClassroomError if invalid_classroom_year?(classroom)

      classroom.calendar && classroom.calendar.classroom_steps.find do |classroom_step|
        classroom_step.to_number == @post_data.step.to_number
      end || @post_data.step
    end

    def teacher
      @post_data.author.current_teacher
    end

    def invalid_classroom_year?(classroom)
      @post_data.step.school_calendar.year != classroom.year
    end
  end
end
