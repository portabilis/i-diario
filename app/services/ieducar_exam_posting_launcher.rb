# Cria o registro de envio ao i-Educar e enfileira o worker que monta as requisições.
# O último envio concluído com os mesmos atributos é a base incremental: só o que mudou depois
# dele é enviado. Envio manual e automático nunca compartilham essa base — por isso `automatic`
# precisa vir sempre nos atributos.
class IeducarExamPostingLauncher
  def self.call(attributes:, entity_id:, force_posting: false, queue: nil)
    new(attributes: attributes, entity_id: entity_id, force_posting: force_posting, queue: queue).call
  end

  def initialize(attributes:, entity_id:, force_posting: false, queue: nil)
    # Sem a chave, o registro nasceria manual (default da coluna) e a busca pelo último envio
    # deixaria de separar as duas populações — um envio automático de uma turma só viraria base do
    # manual, que passaria a pular as demais turmas.
    raise ArgumentError, 'attributes precisa informar automatic' unless attributes.key?(:automatic)

    @attributes = attributes
    @entity_id = entity_id
    @force_posting = ActiveModel::Type::Boolean.new.cast(force_posting) || false
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

  # Envio que não gerou nenhuma requisição não pode virar a marca d'água: como o corte é a data de
  # criação dele, tudo que foi lançado antes ficaria abaixo da linha e nunca mais seria enviado.
  # Turma sem vínculo ativo do professor (estado por onde a sincronização passa) cai nesse caso.
  def last_completed_posting_id
    IeducarApiExamPosting.joins(:worker_batch)
                         .where(attributes)
                         .where(status: ApiSynchronizationStatus::COMPLETED)
                         .where('worker_batches.total_workers > 0')
                         .last
                         .try(:id)
  end
end
