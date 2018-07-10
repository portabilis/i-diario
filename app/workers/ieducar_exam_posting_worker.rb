class IeducarExamPostingWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, queue: :exam_posting, unique: :until_and_while_executing

  sidekiq_retries_exhausted do |msg, ex|
    entity_id, posting_id = msg['args']
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"
      posting.add_error!('Ocorreu um erro desconhecido.', custom_error)
      posting.finish!
    end
  end

  def perform(entity_id, posting_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      case posting.post_type
      when ApiPostingTypes::NUMERICAL_EXAM
        ExamPoster::NumericalExamPoster.post!(posting, entity_id)
      when ApiPostingTypes::CONCEPTUAL_EXAM
        ExamPoster::ConceptualExamPoster.post!(posting, entity_id)
      when ApiPostingTypes::DESCRIPTIVE_EXAM
        ExamPoster::DescriptiveExamPoster.post!(posting, entity_id)
      when ApiPostingTypes::ABSENCE
        ExamPoster::AbsencePoster.post!(posting, entity_id)
      when ApiPostingTypes::FINAL_RECOVERY
        ExamPoster::FinalRecoveryPoster.post!(posting, entity_id)
      when ApiPostingTypes::SCHOOL_TERM_RECOVERY
        ExamPoster::SchoolTermRecoveryPoster.post!(posting, entity_id)
      end
    end
  end
end
