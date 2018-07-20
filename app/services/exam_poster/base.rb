module ExamPoster
  class Base
    class InvalidClassroomError < StandardError; end

    attr_accessor :warning_messages, :requests

    def initialize(post_data, entity_id = nil, batch = nil)
      @post_data = post_data
      @entity_id = entity_id
      @worker_batch = post_data.worker_batch
      @warning_messages = []
      @requests = []
    end

    def self.post!(post_data, entity_id = nil)
      new(post_data, entity_id).post!
    end

    def post!
      generate_requests

      @post_data.add_warning!(@warning_messages) if @warning_messages.present?

      worker_batch.update_attributes!(total_workers: requests.count)

      if requests.present?
        requests.each do |request|
          Ieducar::SendPostWorker.perform_async(entity_id, @post_data.id, request)
        end
      else
        @post_data.finish!
      end
    end

    private

    attr_reader :worker_batch, :entity_id

    def step_exists_for_classroom?(classroom)
      return false if invalid_classroom_year?(classroom)

      classroom.calendar.blank? || classroom.calendar.classroom_steps.any? do |classroom_step|
        classroom_step.to_number == @post_data.step.to_number
      end
    end

    def get_step(classroom)
      raise InvalidClassroomError if invalid_classroom_year?(classroom)

      classroom.calendar && classroom.calendar.classroom_steps.find do |classroom_step|
        classroom_step.to_number == @post_data.step.to_number
      end || @post_data.step
    end

    def teacher
      @post_data.teacher || @post_data.author.current_teacher
    end

    def invalid_classroom_year?(classroom)
      @post_data.step.school_calendar.year != classroom.year
    end
  end
end
