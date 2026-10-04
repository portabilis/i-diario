require 'rails_helper'

# A conexão do tenant precisa entrar na transação dos fixtures desde o primeiro exemplo que a abre.
# O pool de cada Entity nasce no primeiro `using_connection` do processo: sem criá-lo antes do
# `enlist`, o exemplo que o cria grava fora da transação e o registro fica no banco para o resto da
# execução, quebrando specs que dependem de dado global de fixture.
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
end
