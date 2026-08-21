require 'rails_helper'

RSpec.describe Entity, :type => :model do
  context "Validations" do
    it { expect(subject).to validate_presence_of(:name) }
    it { expect(subject).to validate_presence_of(:domain) }
    it { expect(subject).to validate_presence_of(:config) }
  end

  describe '.current' do
    let(:entity) { create(:entity, name: 'Primeira', domain: 'primeira.current.test') }

    it 'is thread-local: a value set in one thread is not visible in another' do
      Entity.current = entity

      other_thread_value = Thread.new { Entity.current }.value

      expect(other_thread_value).to be_nil
      expect(Entity.current).to eq(entity)
    end

    it 'is not clobbered by a concurrent thread setting another entity' do
      other_entity = create(:entity, name: 'Outra', domain: 'outra.current.test')

      Entity.current = entity
      Thread.new { Entity.current = other_entity }.join

      expect(Entity.current).to eq(entity)
    end
  end

  describe '#using_connection' do
    let(:entity) { create(:entity, name: 'Primeira', domain: 'primeira.connection.test') }
    let(:other_entity) { create(:entity, name: 'Outra', domain: 'outra.connection.test') }

    it 'sets Entity.current inside the block' do
      entity.using_connection do
        expect(Entity.current).to eq(entity)
      end
    end

    it 'restores the previous Entity.current after the block' do
      Entity.current = other_entity

      entity.using_connection {}

      expect(Entity.current).to eq(other_entity)
    end

    it 'restores the previous Entity.current when the block raises' do
      Entity.current = other_entity

      expect do
        entity.using_connection { raise 'boom' }
      end.to raise_error('boom')

      expect(Entity.current).to eq(other_entity)
    end
  end
end
