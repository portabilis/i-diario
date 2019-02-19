require 'spec_helper'

RSpec.describe EntityCreator, type: :service do
  describe "with correct params" do
    let(:options) do
      {
        "NAME"     => "Entidade X",
        "DOMAIN"   => "entidade_x.com",
        "DATABASE" => "entidade_x_database",
      }
    end

    it 'create an Entity' do
      allow(EntityDatabaseCreator).to receive(:create).and_return(true)

      creator = EntityCreator.new(options)

      expect(EntityDatabaseCreator).to receive(:create).with(options["DATABASE"])

      expect{ creator.setup }.to change{Entity.count}.by(1)
    end

    it 'set success message' do
      allow(EntityDatabaseCreator).to receive(:create).and_return(true)

      creator = EntityCreator.new(options)

      expect(EntityDatabaseCreator).to receive(:create).with(options["DATABASE"])

      creator.setup

      expect(creator.status).to eq "\nSetup realizado com sucesso."
    end
  end

  describe "without correct params" do
    let(:options) do
      {
        "DOMAIN"   => "entidade_x.com",
        "DATABASE" => "entidade_x_database",
      }
    end

    it 'set error message' do
      creator = EntityCreator.new(options)

      expect(EntityDatabaseCreator).to_not receive(:create)

      creator.setup

      expect(creator.status).to eq "\nNao foi possivel criar a Entidade. Por favor, utilize o seguinte formato:" +
        "\nNAME=\"name\" DOMAIN=\"domain\" DATABASE=\"database\" rake entity:setup" +
        "\nOu verifique se a Entidade ja nao foi criada"
    end
  end
end
