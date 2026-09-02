require 'rails_helper'

RSpec.describe AdvisoryTransactionLock, type: :service do
  let(:key) { 'spec:advisory_transaction_lock' }

  it 'acquires the lock inside a transaction' do
    ActiveRecord::Base.transaction do
      expect(described_class.call(key)).to be_a(PG::Result)
    end
  end

  context 'outside the test transaction', concurrent: true do
    it 'raises when there is no open transaction' do
      expect { described_class.call(key) }.to raise_error(ArgumentError, /transação aberta/)
    end

    it 'makes a second transaction wait until the holder finishes' do
      hold_time = 0.5
      held = Queue.new

      holder = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActiveRecord::Base.transaction do
            described_class.call(key)
            held << true
            sleep(hold_time)
          end
        end
      end

      held.pop
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ActiveRecord::Base.transaction { described_class.call(key) }
      waited = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      holder.join

      expect(waited).to be >= hold_time * 0.8
    end
  end
end
