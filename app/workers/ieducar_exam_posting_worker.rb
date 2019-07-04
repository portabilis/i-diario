class IeducarExamPostingWorker
  include Sidekiq::Worker
  include EntityWorker

  sidekiq_options retry: 2, queue: :exam_posting, unique: :until_and_while_executing, dead: false

  sidekiq_retries_exhausted do |message, exception|
    entity_id, posting_id, params = message['args']
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      posting.add_error!(
        I18n.t('ieducar_api.error.messages.post_error'),
        exception.message
      )
      posting.finish!
    end
  end

  def perform_in_entity(posting_id, queue = 'exam_posting_send')
    posting = IeducarApiExamPosting.find(posting_id)

    case posting.post_type
    when ApiPostingTypes::NUMERICAL_EXAM
      ExamPoster::NumericalExamPoster.post!(posting, EntitySingletoon.current.id, queue)
    when ApiPostingTypes::CONCEPTUAL_EXAM
      ExamPoster::ConceptualExamPoster.post!(posting, EntitySingletoon.current.id, queue)
    when ApiPostingTypes::DESCRIPTIVE_EXAM
      ExamPoster::DescriptiveExamPoster.post!(posting, EntitySingletoon.current.id, queue)
    when ApiPostingTypes::ABSENCE
      ExamPoster::AbsencePoster.post!(posting, EntitySingletoon.current.id, queue)
    when ApiPostingTypes::FINAL_RECOVERY
      ExamPoster::FinalRecoveryPoster.post!(posting, EntitySingletoon.current.id, queue)
    when ApiPostingTypes::SCHOOL_TERM_RECOVERY
      ExamPoster::SchoolTermRecoveryPoster.post!(posting, EntitySingletoon.current.id, queue)
    end
  end
end
