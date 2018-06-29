module Ieducar
  module SendPostPerformer
    def performer(entity_id, posting_id, params)
      entity = Entity.find(entity_id)

      entity.using_connection do
        posting = IeducarApiExamPosting.find(posting_id)

        yield(posting, params)
      end
    end
  end
end
