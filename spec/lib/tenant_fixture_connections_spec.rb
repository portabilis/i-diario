require 'rails_helper'

# A conexão do tenant precisa entrar na transação dos fixtures em dois momentos: quando a Entity já
# existe no início do exemplo e quando ela é criada no meio dele. Nos dois casos o pool nasce sob
# demanda no primeiro `using_connection`; criado durante o exemplo, ele não está na lista que o
# `enlist` leu, e o que se grava por ele fica no banco para o resto da execução, quebrando specs que
# dependem de dado global de fixture.
# `order: :defined`: o exemplo que confere o rollback depende de o exemplo que escreve ter rodado antes.
RSpec.describe 'Tenant connection inside the fixture transaction', order: :defined do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  it 'writes through the tenant connection inside the example transaction' do
    entity.using_connection do
      create(:test_setting, year: 1999)

      expect(ActiveRecord::Base.connection.transaction_open?).to be(true)
    end
  end

  it 'does not keep what the previous example wrote through the tenant connection' do
    entity.using_connection do
      expect(TestSetting.where(year: 1999)).not_to exist
    end
  end

  context 'when the entity is created inside the example' do
    let(:created_entity) { create(:entity, name: 'Criada no exemplo', domain: 'created.inside.example.test') }

    it 'writes through the new tenant connection inside the example transaction' do
      created_entity.using_connection do
        create(:test_setting, year: 1998)

        expect(ActiveRecord::Base.connection.transaction_open?).to be(true)
      end
    end

    it 'does not keep what the previous example wrote through the new tenant connection' do
      entity.using_connection do
        expect(TestSetting.where(year: 1998)).not_to exist
      end
    end
  end
end
