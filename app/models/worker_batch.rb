class WorkerBatch < ApplicationRecord
  include LifeCycleTimeLoggable

  belongs_to :stateable, polymorphic: true
  has_many :worker_states, dependent: :restrict_with_error

  scope :by_ieducar_synchronizations, -> {
    where(stateable_type: 'IeducarApiSynchronization').joins(
      'INNER JOIN ieducar_api_synchronizations
               ON ieducar_api_synchronizations.id = worker_batches.stateable_id'
    )
  }

  scope :by_full_synchronizations, -> {
    by_ieducar_synchronizations.merge(IeducarApiSynchronization.by_full_synchronizations)
  }

  scope :by_partial_synchronizations, -> {
    by_ieducar_synchronizations.merge(IeducarApiSynchronization.by_partial_synchronizations)
  }

  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { by_status(ApiSynchronizationStatus::COMPLETED) }

  before_create :start

  def done
    $REDIS_DB.get(redis_key).to_i
  end

  def all_workers_finished?
    total_workers > 0 && total_workers == done_workers
  end

  def done_percentage
    return 0   if total_workers.zero?
    return 100 if all_workers_finished?

    ((done.to_f / total_workers.to_f) * 100).round(0)
  end

  def increment
    return if all_workers_finished?

    new_count = $REDIS_DB.incr(redis_key)

    write_heartbeat if heartbeat_due?(new_count)

    if new_count == total_workers
      yield if block_given?

      self.done_workers = new_count
      finish!
    end
  end

  def mark_as_error!
    update(status: ApiSynchronizationStatus::ERROR, ended_at: Time.current)
  end

  private

  def redis_key
    # Usa combinação de ID + UUID para garantir unicidade entre tenants
    # O UUID previne colisão entre diferentes instâncias/tenants
    "worker_batch:#{id}:#{secure_uuid}:done_workers"
  end

  # O updated_at é o sinal de vida que IeducarApiSynchronization#locked? usa para detectar sync travada.
  # Todos os workers do lote incrementam a mesma linha: grava só o worker cujo contador cruza uma faixa de
  # 10% — o INCR do Redis é atômico, então cada contagem sai para um único worker. Sem o total (fase inicial
  # da sync, antes de o DefaultSynchronizer gravá-lo) grava a cada incremento. O incremento que fecha o lote
  # não grava: o finish! em seguida já atualiza a linha.
  def heartbeat_due?(new_count)
    return true if total_workers.zero?
    return false if new_count >= total_workers

    heartbeat_band(new_count) > heartbeat_band(new_count - 1)
  end

  def heartbeat_band(count)
    count * 10 / total_workers
  end

  # Um statement só, sem transação própria, que não espera lock: com a linha travada por outro escritor a
  # gravação é pulada, porque quem segura a linha já está atualizando o lote. FOR NO KEY UPDATE não conflita
  # com o KEY SHARE que a FK de worker_states pega a cada WorkerState criado; FOR UPDATE pularia nesses casos.
  # O update_all não passa por callbacks nem validações, e o model não tem nenhum ligado ao updated_at.
  def write_heartbeat
    WorkerBatch.where(
      'worker_batches.id = (SELECT id FROM worker_batches WHERE id = ? FOR NO KEY UPDATE SKIP LOCKED)', id
    ).update_all(updated_at: Time.current)
  end

  def reset
    start
    self.total_workers = 0
    self.done_workers = 0
    save
    worker_states.delete_all
    $REDIS_DB.del(redis_key)
  end

  def start!
    start
    save!
  end

  def start
    self.status = ApiSynchronizationStatus::STARTED
    self.started_at = Time.current
  end

  def finish!
    update!(
      status: ApiSynchronizationStatus::COMPLETED,
      ended_at: Time.current
    )

    $REDIS_DB.del(redis_key)
  end
end