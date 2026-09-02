require 'rails_helper'

RSpec.describe AdvisoryTransactionLock, type: :service do
  # Um deadlock ou um timeout de lock não chega como classe própria no Rails 5.0: vem embrulhado em
  # StatementInvalid, e só o `cause` diz qual erro do PostgreSQL ocorreu.
  def statement_invalid_caused_by(pg_error_class)
    raise pg_error_class, 'erro do driver'
  rescue pg_error_class
    raise ActiveRecord::StatementInvalid, 'erro embrulhado'
  end

  let(:key) { 'spec:advisory_transaction_lock' }

  it 'returns the block value' do
    expect(described_class.call(key) { :resultado }).to eq(:resultado)
  end

  it 'opens a transaction around the block' do
    described_class.call(key) do
      expect(ActiveRecord::Base.connection.transaction_open?).to eq(true)
    end
  end

  it 'retries a concurrent write and returns the value of the successful attempt' do
    attempts = 0

    result = described_class.call(key) do
      attempts += 1
      raise ActiveRecord::RecordNotUnique, 'duplicate key' if attempts == 1

      :segunda_tentativa
    end

    expect(attempts).to eq(2)
    expect(result).to eq(:segunda_tentativa)
  end

  it 'retries a deadlock, which has no dedicated exception class in this Rails version' do
    attempts = 0

    described_class.call(key) do
      attempts += 1
      statement_invalid_caused_by(PG::TRDeadlockDetected) if attempts == 1
    end

    expect(attempts).to eq(2)
  end

  it 'gives up after the attempt limit and re-raises the original error' do
    attempts = 0

    expect {
      described_class.call(key) do
        attempts += 1
        raise ActiveRecord::RecordNotUnique, 'duplicate key'
      end
    }.to raise_error(ActiveRecord::RecordNotUnique)

    expect(attempts).to eq(described_class::MAX_ATTEMPTS)
  end

  it 'does not retry an error that is not a lost race' do
    attempts = 0

    expect {
      described_class.call(key) do
        attempts += 1
        statement_invalid_caused_by(PG::UndefinedTable)
      end
    }.to raise_error(ActiveRecord::StatementInvalid)

    expect(attempts).to eq(1)
  end

  it 'translates the wait timeout into an error whose message carries no key' do
    expect {
      described_class.call(key) { statement_invalid_caused_by(PG::LockNotAvailable) }
    }.to raise_error(described_class::WaitTimeout, described_class::WAIT_TIMEOUT_MESSAGE)
  end

  context 'against another connection', concurrent: true do
    # O holder sinaliza que entrou e o waiter registra a ordem dos eventos: a prova é que a aquisição
    # do waiter acontece depois do commit do holder, e não quanto tempo ele esperou no relógio.
    it 'makes a second transaction wait until the holder commits' do
      events = Queue.new
      held = Queue.new
      release = Queue.new

      holder = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(key) do
            held << true
            release.pop
            events << :holder_commit
          end
        end
      end

      Timeout.timeout(10) { held.pop }

      waiter = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          described_class.call(key) { events << :waiter_acquire }
        end
      end

      # o waiter já está bloqueado no lock: liberar o holder é o que permite os dois eventos
      release << true
      Timeout.timeout(10) { [holder, waiter].each(&:join) }

      expect([events.pop, events.pop]).to eq([:holder_commit, :waiter_acquire])
    end
  end
end
