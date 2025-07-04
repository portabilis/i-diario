module ConceptualExamsInBatchs
  class DestroyMultiple < Base
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call!
      conceptual_exams = ConceptualExam.where(step_number: conceptual_exam_params[:step_number],
                                              classroom_id: conceptual_exam_params[:classroom_id])

      return true if conceptual_exams.empty?

      begin
        ActiveRecord::Base.transaction do
          conceptual_exams.each do |conceptual_exam|
            conceptual_exam_value = conceptual_exam.conceptual_exam_values
                                                   .find_by(discipline_id: conceptual_exam_params[:discipline_id])

            conceptual_exam_value.destroy!
          end

          conceptual_exams.destroy_all
        end
      end
    end

    private

    def conceptual_exam_params
      params.require(:conceptual_exam)
    end
  end
end
