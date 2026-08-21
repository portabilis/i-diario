require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#handle_customer' do
    let(:entity) { create(:entity, name: 'Reset', domain: 'reset.handle.test') }

    after { Honeybadger.context.clear! }

    before do
      # Espelha o fluxo real: current_entity seta Entity.current como efeito
      # colateral antes do using_connection capturar o valor anterior.
      allow(controller).to receive(:current_entity) do
        Entity.current = entity
        entity
      end
    end

    it 'clears Entity.current after the request' do
      seen_inside = :unset

      controller.send(:handle_customer) { seen_inside = Entity.current }

      expect(seen_inside).to eq(entity)
      expect(Entity.current).to be_nil
    end

    it 'clears Entity.current when the request raises' do
      expect do
        controller.send(:handle_customer) { raise 'boom' }
      end.to raise_error('boom')

      expect(Entity.current).to be_nil
    end
  end
end
