require 'rails_helper'

RSpec.describe WorkerBatch, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:frozen_time) { Time.zone.local(2026, 3, 2, 10, 0, 0) }

  # Cada job do lote lê o próprio objeto antes de incrementar; o secure_uuid que compõe a chave do contador
  # vem do default do banco e só existe no objeto lido de volta.
  def load_batch(batch)
    WorkerBatch.find(batch.id)
  end

  # Número do incremento (1..n) em que cada UPDATE na linha do lote aconteceu, separando o sinal de vida
  # (só updated_at) das demais escritas.
  def run_increments(batch, times)
    heartbeats = []
    other_updates = []
    current = nil

    subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
      sql = payload[:sql]
      next unless sql.start_with?('UPDATE "worker_batches"')

      if sql.start_with?('UPDATE "worker_batches" SET "updated_at"')
        heartbeats << current
      else
        other_updates << current
      end
    end

    (1..times).each do |number|
      current = number
      load_batch(batch).increment
    end

    [heartbeats, other_updates]
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe '#increment' do
    context 'when the batch runs to the end' do
      it 'writes the heartbeat only on the increment that crosses each 10% band and finishes once' do
        batch = create(:worker_batch, total_workers: 1000)

        heartbeats, other_updates = run_increments(batch, 1000)

        expect(heartbeats).to eq([100, 200, 300, 400, 500, 600, 700, 800, 900])
        expect(other_updates).to eq([1000])
      end
    end

    context 'when the batch has fewer workers than bands' do
      it 'writes the heartbeat on every increment except the last one, which finishes the batch' do
        batch = create(:worker_batch, total_workers: 5)

        heartbeats, other_updates = run_increments(batch, 5)

        expect(heartbeats).to eq([1, 2, 3, 4])
        expect(other_updates).to eq([5])
      end
    end

    # Na sincronização, os primeiros jobs incrementam antes de o DefaultSynchronizer gravar o total.
    context 'when the total of workers is not known yet' do
      it 'writes the heartbeat on every increment and does not finish the batch' do
        batch = create(:worker_batch, total_workers: 0)

        heartbeats, other_updates = run_increments(batch, 3)

        expect(heartbeats).to eq([1, 2, 3])
        expect(other_updates).to eq([])
        expect(load_batch(batch).status).to eq(ApiSynchronizationStatus::STARTED)
      end
    end

    context 'when all workers already finished' do
      it 'neither counts nor writes' do
        batch = create(:worker_batch, total_workers: 2, done_workers: 2)

        heartbeats, other_updates = run_increments(batch, 1)

        expect(heartbeats).to eq([])
        expect(other_updates).to eq([])
        expect(load_batch(batch).done).to eq(0)
      end
    end

    context 'when the batch row is free' do
      it 'records the current time as the heartbeat' do
        batch = create(:worker_batch, total_workers: 10)

        travel_to(frozen_time) { load_batch(batch).increment }

        expect(load_batch(batch).updated_at).to eq(frozen_time)
      end
    end

    context 'when the last worker finishes the batch' do
      it 'yields once, closes the batch and clears the counter' do
        batch = create(:worker_batch, total_workers: 3)
        yielded = 0
        finishing_batch = nil

        travel_to(frozen_time) do
          3.times do
            finishing_batch = load_batch(batch)
            finishing_batch.increment { yielded += 1 }
          end
        end

        expect(yielded).to eq(1)
        expect(finishing_batch.all_workers_finished?).to eq(true)
        expect(load_batch(batch)).to have_attributes(
          status: ApiSynchronizationStatus::COMPLETED,
          done_workers: 3,
          ended_at: frozen_time
        )
        expect(load_batch(batch).done).to eq(0)
      end
    end

    # Cada job roda na própria conexão; a outra transação segura a linha como um job de outro processo.
    context 'when another transaction holds the batch row', concurrent: true do
      def hold_batch_row(sql)
        holder = ActiveRecord::Base.connection_pool.checkout
        holder.execute('BEGIN')
        holder.execute(sql)

        yield
      ensure
        if holder
          holder.execute('ROLLBACK')
          ActiveRecord::Base.connection_pool.checkin(holder)
        end
      end

      def in_own_connection(&block)
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection(&block)
        end
      end

      it 'skips the heartbeat instead of waiting for the lock' do
        batch = create(:worker_batch, total_workers: 10)
        updated_at = load_batch(batch).updated_at
        incrementer = nil
        finished_while_held = nil

        hold_batch_row("UPDATE worker_batches SET updated_at = now() WHERE id = #{batch.id}") do
          incrementer = in_own_connection { load_batch(batch).increment }
          finished_while_held = incrementer.join(2)
        end
        incrementer.join

        expect(finished_while_held).to eq(incrementer)
        expect(load_batch(batch).updated_at).to eq(updated_at)
      end

      # A FK de worker_states pega KEY SHARE na linha do lote a cada WorkerState criado; o sinal de vida não
      # pode ser pulado por isso.
      it 'writes the heartbeat while a worker state of the batch is being created' do
        batch = create(:worker_batch, total_workers: 10)
        incrementer = nil
        finished_while_held = nil

        travel_to(frozen_time) do
          hold_batch_row(
            'INSERT INTO worker_states (kind, created_at, updated_at, worker_batch_id) ' \
            "VALUES ('SchoolCalendarsSynchronizer', now(), now(), #{batch.id})"
          ) do
            incrementer = in_own_connection { load_batch(batch).increment }
            finished_while_held = incrementer.join(2)
          end
        end
        incrementer.join

        expect(finished_while_held).to eq(incrementer)
        expect(load_batch(batch).updated_at).to eq(frozen_time)
      end

      it 'waits for the lock to close the batch on the last increment' do
        batch = create(:worker_batch, total_workers: 1)
        incrementer = nil
        finished_while_held = nil

        hold_batch_row("UPDATE worker_batches SET updated_at = now() WHERE id = #{batch.id}") do
          incrementer = in_own_connection do
            finishing_batch = load_batch(batch)
            yielded = 0
            finishing_batch.increment { yielded += 1 }

            [yielded, finishing_batch.all_workers_finished?]
          end
          finished_while_held = incrementer.join(1)
        end

        expect(finished_while_held).to eq(nil)
        expect(incrementer.value).to eq([1, true])
        expect(load_batch(batch)).to have_attributes(
          status: ApiSynchronizationStatus::COMPLETED,
          done_workers: 1
        )
      end
    end
  end
end
