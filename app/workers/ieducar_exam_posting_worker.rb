class IeducarExamPostingWorker
  include Sidekiq::Worker

  def perform(entity_id, posting_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      begin
        messages =
          case posting.post_type
          when ApiPostingTypes::NUMERICAL_EXAM
            ExamPoster::NumericalExamPoster.post!(posting)
          when ApiPostingTypes::CONCEPTUAL_EXAM
            ExamPoster::ConceptualExamPoster.post!(posting)
          when ApiPostingTypes::DESCRIPTIVE_EXAM
            ExamPoster::DescriptiveExamPoster.post!(posting)
          when ApiPostingTypes::ABSENCE
            ExamPoster::AbsencePoster.post!(posting)
          when ApiPostingTypes::FINAL_RECOVERY
            ExamPoster::FinalRecoveryPoster.post!(posting)
          when ApiPostingTypes::SCHOOL_TERM_RECOVERY
            ExamPoster::SchoolTermRecoveryPoster.post!(posting)
          end

        posting.mark_as_warning!(messages[:warning_messages]) if !messages[:warning_messages].empty?

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
