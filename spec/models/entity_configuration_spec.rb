require 'rails_helper'

RSpec.describe EntityConfiguration, :type => :model do
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

      it "caches the result in Rails.cache" do
        entity_configuration.cached_logo_data

        cache_key = "entity_logo_data:#{entity_configuration.id}:logo.png"
        expect(memory_store.read(cache_key)).to be_present
      end

      it "uses cache on second call without fetching again" do
        entity_configuration.cached_logo_data

        expect(entity_configuration.logo).not_to receive(:read)
        entity_configuration.cached_logo_data
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
