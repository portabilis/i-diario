module ExamPoster
  class Base
    attr_accessor :warning_messages

    def initialize(post_data)
      @post_data = post_data
      @warning_messages = []
    end

    def post!
      raise NotImplementedError
    end

    def step_exists_for_classroom?(classroom)
      if classroom.calendar
        classroom.calendar.classroom_steps.find_by_id(@post_data.step.id).present?
      else
        @post_data.step.school_calendar.year == classroom.year
      end
    end

    def teacher
      @post_data.teacher || @post_data.author.current_teacher
    end
  end
end
