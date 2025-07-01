module ConceptualExamsInBatchs
  class CreateOrUpdateMultiple < Base
    attr_reader :params, :teacher, :user, :step

    def initialize(params, teacher, user, step)
      @params = params
      @teacher = teacher
      @user = user
      @step = step
    end

    def call!
      any_changed = false
      @classroom = Classroom.find(base_params[:classroom_id])

      begin
        ActiveRecord::Base.transaction do
          params[:conceptual_exam_values_attributes].each do |_key, conceptual_exam_attributes|
            conceptual_exam = find_or_initialize_conceptual_exam(
              conceptual_exam_attributes[:student_id],
              params[:recorded_at],
              @classroom,
              teacher.id,
              user,
              step
            )

            next if conceptual_exam.nil?

            conceptual_exam_value = conceptual_exam.conceptual_exam_values
                                                   .find_or_initialize_by(
                                                     discipline_id: conceptual_exam_attributes[:discipline_id]
                                                   )

            conceptual_exam_value.assign_attributes(conceptual_exam_attributes.except(:student_id, :_destroy))

            any_changed = true if conceptual_exam_value.changed?

            conceptual_exam_value.save!
          end
        end
      end

      clear_status_cache if any_changed

      true
    end

    private

    def base_params
      params.permit(
        :unity_id,
        :classroom_id,
        :recorded_at,
        :student_id,
        :step_id,
        conceptual_exam_values_attributes: [
          :id,
          :discipline_id,
          :value,
          :exempted_discipline,
          :_destroy
        ]
      )
    end

    def clear_status_cache
      cache_key = "#{StepsFetcher.new(@classroom).steps.size}-steps-#{@classroom.id}-#{@teacher.id}"

      Rails.cache.delete(cache_key)
    end
  end
end
