require 'rails_helper'

RSpec.describe EntityConfiguration, :type => :model do
  describe "cnpj validation" do
    it "accepts a valid alphanumeric CNPJ" do
      entity_configuration = EntityConfiguration.new(cnpj: '12.ABC.345/01DE-35')

      entity_configuration.valid?

      expect(entity_configuration.errors[:cnpj]).to be_empty
    end

    it "accepts a valid numeric CNPJ for backward compatibility" do
      entity_configuration = EntityConfiguration.new(cnpj: '11.222.333/0001-81')

      entity_configuration.valid?

      expect(entity_configuration.errors[:cnpj]).to be_empty
    end

    it "accepts a blank CNPJ" do
      entity_configuration = EntityConfiguration.new(cnpj: '')

      entity_configuration.valid?

      expect(entity_configuration.errors[:cnpj]).to be_empty
    end

    it "rejects a CNPJ with an incorrect verifier digit" do
      entity_configuration = EntityConfiguration.new(cnpj: '12.ABC.345/01DE-34')

      entity_configuration.valid?

      expect(entity_configuration.errors.details[:cnpj]).to contain_exactly(error: :incorrect_format)
    end

    it "upcases the alphanumeric CNPJ before validating" do
      entity_configuration = EntityConfiguration.new(cnpj: '12abc34501de35')

      entity_configuration.valid?

      expect(entity_configuration.cnpj).to eq('12ABC34501DE35')
      expect(entity_configuration.errors[:cnpj]).to be_empty
    end
  end

  describe ".current" do
    context "when it doesn't have a existent configuration" do
      it "returns a new configuration" do
        expect(EntityConfiguration.current).to be_new_record
      end
    end

    context "when it has a persited configuration" do
      it "return the first persited configuration" do
        entity_configuration = EntityConfiguration.create
        expect(EntityConfiguration.current).to eq entity_configuration
      end
    end
  end

  describe "#cached_logo_data" do
    subject(:entity_configuration) { EntityConfiguration.create }

    context "when logo is blank" do
      it "returns nil" do
        expect(entity_configuration.cached_logo_data).to be_nil
      end
    end

    context "when logo is present" do
      let(:image_data) { File.read(Rails.root.join('spec', 'fixtures', 'image.png'), mode: 'rb') }
      let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }
      let(:current_entity) { build(:entity, id: 10) }

      # Entity.current é global (cattr): restaurar evita vazar para outros specs.
      around do |example|
        previous_entity = Entity.current
        Entity.current = current_entity
        example.run
        Entity.current = previous_entity
      end

      before do
        allow(Rails).to receive(:cache).and_return(memory_store)
        allow(entity_configuration.logo).to receive(:blank?).and_return(false)
        allow(entity_configuration.logo).to receive(:url).and_return('http://example.com/logo.png')
        allow(entity_configuration.logo).to receive(:identifier).and_return('logo.png')
        allow(entity_configuration.logo).to receive(:read).and_return(image_data)
      end

      it "returns hash with raw binary data and content type" do
        result = entity_configuration.cached_logo_data

        expect(result).to be_a(Hash)
        expect(result[:data]).to eq(image_data)
        expect(result[:content_type]).to eq('image/png')
      end

      it "caches the result in Rails.cache under the current entity" do
        entity_configuration.cached_logo_data

        cache_key = "entity_logo_data:10:#{entity_configuration.id}:logo.png"
        expect(memory_store.read(cache_key)).to eq(data: image_data, content_type: 'image/png')
      end

      it "uses cache on second call without fetching again" do
        entity_configuration.cached_logo_data

        expect(entity_configuration.logo).not_to receive(:read)
        entity_configuration.cached_logo_data
      end

      # O cache é um só para todas as redes e o id da configuração é o mesmo em
      # cada banco: só a rede na chave separa dois brasões de mesmo nome.
      it "does not serve one entity's logo to another with the same file name" do
        entity_configuration.cached_logo_data

        other_image = 'other-network-logo'
        allow(entity_configuration.logo).to receive(:read).and_return(other_image)
        Entity.current = build(:entity, id: 20)

        expect(entity_configuration.cached_logo_data[:data]).to eq(other_image)
        expect(memory_store.read("entity_logo_data:10:#{entity_configuration.id}:logo.png")[:data]).to eq(image_data)
        expect(memory_store.read("entity_logo_data:20:#{entity_configuration.id}:logo.png")[:data]).to eq(other_image)
      end

      context "when there is no current entity" do
        before { Entity.current = nil }

        it "reads the logo without touching the cache" do
          result = entity_configuration.cached_logo_data

          expect(result[:data]).to eq(image_data)
          expect(memory_store.instance_variable_get(:@data)).to be_empty
        end
      end

      describe "cache invalidation" do
        it "removes the current and the previous logo of the current entity" do
          old_key = "entity_logo_data:10:#{entity_configuration.id}:old.png"
          new_key = "entity_logo_data:10:#{entity_configuration.id}:logo.png"
          memory_store.write(old_key, 'old')
          memory_store.write(new_key, 'new')
          allow(entity_configuration).to receive(:logo_was).and_return(double(identifier: 'old.png'))

          entity_configuration.send(:invalidate_logo_cache)

          expect(memory_store.read(old_key)).to be_nil
          expect(memory_store.read(new_key)).to be_nil
        end

        it "leaves the cache of other entities untouched" do
          other_key = "entity_logo_data:20:#{entity_configuration.id}:logo.png"
          memory_store.write(other_key, 'other')
          allow(entity_configuration).to receive(:logo_was).and_return(nil)

          entity_configuration.send(:invalidate_logo_cache)

          expect(memory_store.read(other_key)).to eq('other')
        end
      end
    end

    context "when an error occurs fetching the logo" do
      before do
        allow(entity_configuration.logo).to receive(:blank?).and_return(false)
        allow(entity_configuration.logo).to receive(:url).and_return('http://example.com/logo.png')
        allow(entity_configuration.logo).to receive(:identifier).and_return('logo.png')
        allow(entity_configuration.logo).to receive(:read).and_raise(StandardError.new('Connection refused'))
      end

      it "returns nil" do
        expect(entity_configuration.cached_logo_data).to be_nil
      end
    end
  end

  describe "#cached_logo" do
    subject(:entity_configuration) { EntityConfiguration.create }

    context "when cached_logo_data returns nil" do
      before do
        allow(entity_configuration).to receive(:cached_logo_data).and_return(nil)
      end

      it "returns nil" do
        expect(entity_configuration.cached_logo).to be_nil
      end
    end

    context "when cached_logo_data returns data" do
      let(:image_data) { 'fake image binary data' }

      before do
        allow(entity_configuration).to receive(:cached_logo_data).and_return(
          { data: image_data, content_type: 'image/png' }
        )
      end

      it "returns a StringIO with raw image data" do
        result = entity_configuration.cached_logo

        expect(result).to be_a(StringIO)
        expect(result.read).to eq(image_data)
      end
    end
  end

  describe "#logo_base64_data_uri" do
    subject(:entity_configuration) { EntityConfiguration.create }

    context "when cached_logo_data returns nil" do
      before do
        allow(entity_configuration).to receive(:cached_logo_data).and_return(nil)
      end

      it "returns nil" do
        expect(entity_configuration.logo_base64_data_uri).to be_nil
      end
    end

    context "when cached_logo_data returns data" do
      let(:image_data) { 'fake image binary data' }

      before do
        allow(entity_configuration).to receive(:cached_logo_data).and_return(
          { data: image_data, content_type: 'image/png' }
        )
      end

      it "returns a data URI string" do
        result = entity_configuration.logo_base64_data_uri

        expect(result).to eq("data:image/png;base64,#{Base64.strict_encode64(image_data)}")
      end
    end
  end
end
