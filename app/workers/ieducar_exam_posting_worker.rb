class IeducarExamPostingWorker
  include Sidekiq::Worker

  sidekiq_options retry: true, queue: :exam_posting, unique: :until_and_while_executing

  def perform(entity_id, posting_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      worker_batch = WorkerBatch.
        find_or_create_by!(main_job_class: 'IeducarExamPostingWorker',
                           main_job_id: self.jid)

      begin
        messages =
          case posting.post_type
          when ApiPostingTypes::NUMERICAL_EXAM
            ExamPoster::NumericalExamPoster.post!(posting, entity_id, worker_batch)
          when ApiPostingTypes::CONCEPTUAL_EXAM
            ExamPoster::ConceptualExamPoster.post!(posting, entity_id, worker_batch)
          when ApiPostingTypes::DESCRIPTIVE_EXAM
            ExamPoster::DescriptiveExamPoster.post!(posting, entity_id, worker_batch)
          when ApiPostingTypes::ABSENCE
            ExamPoster::AbsencePoster.post!(posting, entity_id, worker_batch)
          when ApiPostingTypes::FINAL_RECOVERY
            ExamPoster::FinalRecoveryPoster.post!(posting, entity_id, worker_batch)
          when ApiPostingTypes::SCHOOL_TERM_RECOVERY
            ExamPoster::SchoolTermRecoveryPoster.post!(posting, entity_id, worker_batch)
          end

        posting.mark_as_warning!(messages[:warning_messages]) if !messages[:warning_messages].empty?

      rescue IeducarApi::Base::ApiError => e
        if e.message.include? 'Request Timeout'
          IeducarExamPostingWorker.perform_async(entity_id, posting_id)
        else
          posting.mark_as_error!('Ocorreu um erro desconhecido.', e.message)
        end

        raise e
      rescue Exception => e
        posting.mark_as_error!('Ocorreu um erro desconhecido.')
        raise e
      end
    end
  end
end
