class IeducarExamPostingWorker
  include Sidekiq::Worker

  def perform(entity_id, posting_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      begin
        case posting.post_type
        when ApiPostingTypes::NUMERICAL_EXAMS
          NumericalExamPosting.post!(posting)
        when ApiPostingTypes::CONCEPTUAL_EXAMS
          ConceptualExamPosting.post!(posting)
        when ApiPostingTypes::DESCRIPTIVE_EXAMS
          DescriptiveExamPosting.post!(posting)
        when ApiPostingTypes::ABSENCES
          AbsencePosting.post!(posting)
        when ApiPostingTypes::FINAL_RECOVERIES
          FinalRecoveryPoster.post!(posting)
        end

        posting.mark_as_completed! 'Envio realizado com sucesso!'
      rescue IeducarApi::Base::ApiError => e
        posting.mark_as_error!(e.message)
      rescue Exception => e
        posting.mark_as_error!('Ocorreu um erro desconhecido.')

        raise e
      end
    end
  end
end
