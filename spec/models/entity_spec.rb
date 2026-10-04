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

    after { Honeybadger.context.clear! }

    it 'sets Entity.current inside the block' do
      seen_inside = :unset

      entity.using_connection { seen_inside = Entity.current }

      expect(seen_inside).to eq(entity)
    end

    it 'restores the previous Entity.current after the block' do
      Entity.current = other_entity

      entity.using_connection {}

      expect(Entity.current).to eq(other_entity)
    end

    it 'restores Entity.current to nil after a top-level block' do
      entity.using_connection {}

      expect(Entity.current).to be_nil
    end

    it 'restores the previous Entity.current when the block raises' do
      Entity.current = other_entity

      expect do
        entity.using_connection { raise 'boom' }
      end.to raise_error('boom')

      expect(Entity.current).to eq(other_entity)
    end

    it 'restores the Honeybadger entity tag after a nested block' do
      entity.using_connection do
        other_entity.using_connection {}

        expect(Honeybadger.get_context[:entity]).to eq(name: entity.name, id: entity.id)
      end
    end

    it 'keeps the Honeybadger entity tag of the block when completing inside a rescue handler' do
      # Cenário sidekiq_retries_exhausted: $! está setado durante o handler,
      # então o restore é pulado e a tag fica na entidade do próprio bloco.
      Honeybadger.context(entity: { name: other_entity.name, id: other_entity.id })

      begin
        raise 'expected error'
      rescue RuntimeError
        entity.using_connection {}
      end

      expect(Honeybadger.get_context[:entity]).to eq(name: entity.name, id: entity.id)
    end

    it 'keeps the Honeybadger entity tag of the failing entity when the block raises' do
      expect do
        entity.using_connection do
          other_entity.using_connection { raise 'boom' }
        end
      end.to raise_error('boom')

      expect(Honeybadger.get_context[:entity]).to eq(name: other_entity.name, id: other_entity.id)
    end
  end
end
