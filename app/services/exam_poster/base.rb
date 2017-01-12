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
      return true unless classroom.calendar

      step_exists = false
      classroom.calendar.classroom_steps.each do |classroom_step|
        if classroom_step.to_number == @post_data.step.to_number
          step_exists = true
          break
        end
      end
      step_exists
    end

    def has_classroom_steps(classroom)
      classroom.calendar
    end

    def get_step(classroom)
      step = @post_data.step
      if classroom.calendar
        classroom.calendar.classroom_steps.each do |classroom_step|
          if classroom_step.to_number == @post_data.step.to_number
            step = classroom_step
            break
          end
        end
      else
        school_calendar = SchoolCalendar.by_unity_id(classroom.unity_id).by_school_day(Time.zone.today).first

        school_calendar.steps.each do |school_step|
          if school_step.to_number == @post_data.step.to_number
            step = school_step
            break
          end
        end
      end
      step
    end

    def teacher
      @post_data.author.current_teacher
    end
  end
end
