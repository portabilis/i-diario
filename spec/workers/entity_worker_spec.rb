require 'rails_helper'

RSpec.describe EntityWorker do
  class DummyWorker
    include EntityWorker

    def self.perform_async *args
    end
  end

  class DummyWorkerWithPerformInEntity
    include EntityWorker

    attr_accessor :entity, :args

    def perform_in_entity *args
      @entity = EntitySingletoon.current
      @args = args
    end
  end

  let!(:entity) { create(:entity, domain: :foo) }

  describe '#perform' do
    subject {
      DummyWorkerWithPerformInEntity.new.tap do |dummy|
        dummy.perform entity.id, :arg1, :arg2
      end
    }

    it 'should call perform_in_entity within entity context' do
      expect(subject.entity).to eql(entity)
    end

    it 'should call perform_in_entity with other args' do
      expect(subject.args).to eql([:arg1, :arg2])
    end

    context "without override perform_in_entity" do
      subject {
        DummyWorker.new.tap do |dummy|
          dummy.perform entity.id
        end
      }

      it "should raise not implemented error" do
        expect {
          subject
        }.to raise_error(NotImplementedError, "You should implement perform_in_entity method")
      end
    end
  end

  describe ".perform_current_entity" do
    it "should call perform_async with current entity" do
      EntitySingletoon.set entity

      allow(DummyWorker).to receive(:perform).with(entity.id, :foo, :bar).and_return(nil)

      DummyWorker.perform_current_entity :foo, :bar
    end
  end

end
