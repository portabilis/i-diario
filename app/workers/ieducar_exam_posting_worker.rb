class IeducarExamPostingWorker
  include Sidekiq::Worker

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

    Honeybadger.notify(exception)
  end

  def perform(entity_id, posting_id, queue = 'exam_posting_send')
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      case posting.post_type
      when ApiPostingTypes::NUMERICAL_EXAM, ApiPostingTypes::SCHOOL_TERM_RECOVERY
        ExamPoster::NumericalExamPoster.post!(posting, entity_id, queue)
      when ApiPostingTypes::CONCEPTUAL_EXAM
        ExamPoster::ConceptualExamPoster.post!(posting, entity_id, queue)
      when ApiPostingTypes::DESCRIPTIVE_EXAM
        ExamPoster::DescriptiveExamPoster.post!(posting, entity_id, queue)
      when ApiPostingTypes::ABSENCE
        ExamPoster::AbsencePoster.post!(posting, entity_id, queue)
      when ApiPostingTypes::FINAL_RECOVERY
        ExamPoster::FinalRecoveryPoster.post!(posting, entity_id, queue)
      end
    end
  end
end
