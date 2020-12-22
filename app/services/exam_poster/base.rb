module ExamPoster
  class Base
    class InvalidClassroomError < StandardError; end

    attr_accessor :warning_messages, :requests

    def initialize(post_data, entity_id, queue = nil)
      @post_data = post_data
      @entity_id = entity_id
      @worker_batch = post_data.worker_batch
      @warning_messages = []
      @requests = []
      @queue = queue || 'critical'
    end

    def self.post!(post_data, entity_id, queue = nil)
      new(post_data, entity_id, queue).post!
    end

    def post!
      generate_requests

      @post_data.add_warning!(@warning_messages) if @warning_messages.present?

      worker_batch.update_attributes!(total_workers: requests.count)

      if requests.present?
        requests.each do |request|
          Ieducar::SendPostWorker.set(queue: @queue).perform_in(
            1.second,
            entity_id,
            @post_data.id,
            request[:request],
            request[:info],
            @queue,
            0
          )
        end
      else
        @post_data.finish!
      end
    end

    private

    attr_reader :worker_batch, :entity_id

    def step_exists_for_classroom?(classroom)
      return false if invalid_classroom_year?(classroom)

      get_step_by_step_number(classroom, @post_data.step.to_number).present?
    end

    def get_step(classroom)
      raise InvalidClassroomError if invalid_classroom_year?(classroom)

      get_step_by_step_number(classroom, @post_data.step.to_number) || @post_data.step
    end

    def same_unity?(classroom)
      classroom.unity_id == @post_data.step.school_calendar.unity_id
    end

    def get_step_by_step_number(classroom, step_number)
      current_step_exam_poster = "#{@entity_id}_#{classroom.id}_#{step_number}_current_step_exam_poster"

      Rails.cache.fetch(current_step_exam_poster, expires_in: 5.minutes) do
        StepsFetcher.new(classroom).step(step_number)
      end
    end

    def teacher
      @teacher ||= @post_data.teacher || @post_data.author.current_teacher
    end

    def classrooms
      @classrooms ||= teacher.classrooms.uniq
    end

    def classroom_ids
      @classroom_ids ||= teacher.classrooms.pluck(:id).uniq
    end

    def discipline_ids
      @discipline_ids ||= TeacherDisciplineClassroom.where(
        classroom_id: classroom_ids,
        teacher_id: teacher.id
      ).pluck(:discipline_id).uniq
    end

    def invalid_classroom_year?(classroom)
      @post_data.step.school_calendar.year != classroom.year
    end

    def can_post?(classroom)
      return false if classroom.blank?
      return false unless classroom.can_post

      classroom.post_info &&
        same_unity?(classroom) &&
        step_exists_for_classroom?(classroom)
    end
  end
end
