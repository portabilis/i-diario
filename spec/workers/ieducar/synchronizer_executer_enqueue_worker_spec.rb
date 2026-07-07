# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SynchronizerExecuterEnqueueWorker, type: :worker do
  let(:entity) { Entity.find_by_domain('test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:synchronization) do
    create(:ieducar_api_synchronization, status: ApiSynchronizationStatus::STARTED)
  end
  let(:worker_batch) { create(:worker_batch) }
  let(:klass) { 'SchoolCalendarClassroomsSynchronizer' }
  let(:params) do
    {
      'entity_id' => entity.id,
      'synchronization_id' => synchronization.id,
      'worker_batch_id' => worker_batch.id,
      'klass' => klass,
      'year' => 2026,
      'unity_api_code' => 1
    }
  end
  let(:lock_key) { subject.send(:enqueue_lock_key, params.with_indifferent_access) }

  before do
    orchestrator = instance_double(SynchronizationOrchestrator, can_synchronize?: true)
    allow(SynchronizationOrchestrator).to receive(:new).and_return(orchestrator)
    allow(SynchronizerExecuterWorker).to receive(:set).and_return(SynchronizerExecuterWorker)
    allow(SynchronizerExecuterWorker).to receive(:perform_async)
  end

  after { $REDIS_DB.del(lock_key) }

  describe '#enqueue_lock_key' do
    # O $REDIS_DB é compartilhado entre todas as entidades, mas worker_batch_id é
    # auto-increment por tenant. Sem o entity_id na chave, duas entidades colidiriam
    # e a segunda perderia o enqueue.
    it 'includes the entity_id to avoid collisions between entities on the shared Redis' do
      key_entity_1 = subject.send(:enqueue_lock_key, params.merge('entity_id' => 1).with_indifferent_access)
      key_entity_2 = subject.send(:enqueue_lock_key, params.merge('entity_id' => 2).with_indifferent_access)

      expect(key_entity_1).to eq("synchronizer_enqueue_lock:1:#{worker_batch.id}:#{klass}:2026:1")
      expect(key_entity_1).not_to eq(key_entity_2)
    end
  end

  describe '#perform' do
    it 'enqueues the executer, creates the worker_state and releases the lock at the end' do
      expect {
        subject.perform(params)
      }.to change(WorkerState, :count).by(1)

      expect(SynchronizerExecuterWorker).to have_received(:perform_async).once
      expect($REDIS_DB.get(lock_key)).to be_nil
    end

    context 'when the lock is already held by another parallel execution' do
      before { $REDIS_DB.set(lock_key, '1', nx: true, ex: 30) }

      it 'does not enqueue the executer nor create a duplicated worker_state' do
        expect {
          subject.perform(params)
        }.not_to change(WorkerState, :count)

        expect(SynchronizerExecuterWorker).not_to have_received(:perform_async)
      end

      it 'does not remove the lock that belongs to the execution that acquired it' do
        subject.perform(params)

        expect($REDIS_DB.get(lock_key)).to eq('1')
      end
    end
  end
end
