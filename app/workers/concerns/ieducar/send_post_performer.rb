module Ieducar
  module SendPostPerformer
    def performer(entity_id, posting_id, params, worker_batch_id)
      entity = Entity.find(entity_id)

      entity.using_connection do
        posting = IeducarApiExamPosting.find(posting_id)

        yield(posting, params, worker_batch_id)
      end
    end
  end
end
