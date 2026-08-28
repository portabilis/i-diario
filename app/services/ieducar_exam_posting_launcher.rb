# Cria o registro de envio ao i-Educar e enfileira o worker que monta as requisições.
# O último envio concluído com os mesmos atributos é a base incremental: só o que mudou depois
# dele é enviado. Envio manual e automático nunca compartilham essa base — por isso `automatic`
# precisa vir sempre nos atributos.
class IeducarExamPostingLauncher
  def self.call(attributes:, entity_id:, force_posting: false, queue: nil)
    new(attributes: attributes, entity_id: entity_id, force_posting: force_posting, queue: queue).call
  end

  def initialize(attributes:, entity_id:, force_posting: false, queue: nil)
    @attributes = attributes
    @entity_id = entity_id
    @force_posting = force_posting
    @queue = queue
  end

  def call
    posting = IeducarApiExamPosting.create!(attributes.merge(status: ApiSynchronizationStatus::STARTED))

    WorkerBatch.create!(
      main_job_class: 'IeducarExamPostingWorker',
      main_job_id: enqueue_worker(posting),
      stateable: posting
    )

    posting
  end

  private

  attr_reader :attributes, :entity_id, :force_posting, :queue

  def enqueue_worker(posting)
    worker.perform_in(5.seconds, entity_id, posting.id, last_completed_posting_id, force_posting)
  end

  # A montagem das requisições consulta o banco por aluno; fora da fila padrão ela não disputa
  # conexões do pool com os demais workers.
  def worker
    queue.present? ? IeducarExamPostingWorker.set(queue: queue) : IeducarExamPostingWorker
  end

  def last_completed_posting_id
    IeducarApiExamPosting.where(attributes)
                         .where(status: ApiSynchronizationStatus::COMPLETED)
                         .last
                         .try(:id)
  end
end
