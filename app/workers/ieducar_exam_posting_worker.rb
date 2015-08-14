class IeducarExamPostingWorker
  include Sidekiq::Worker

  def perform(entity_id, posting_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      posting = IeducarApiExamPosting.find(posting_id)

      begin
        # post avaliation
        NumericalExamPosting.post!(posting)

        posting.mark_as_completed! 'Envio realizado com sucesso!'
      rescue IeducarApi::Base::ApiError => e
        posting.mark_as_error!(e.message)
      rescue Exception => e
        # mark with error in any exception
        posting.mark_as_error!("Ocorreu um erro desconhecido.")
        raise e
      end
    end
  end
end
