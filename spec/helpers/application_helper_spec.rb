require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#entity_logo_url_for' do
    it 'points to the logo route with the current file as version' do
      logo = double(blank?: false, identifier: 'brasao-0123456789abcdef.webp')
      entity_configuration = double(logo: logo)

      expect(helper.entity_logo_url_for(entity_configuration)).to eq(
        'http://test.host/entity_logo?v=brasao-0123456789abcdef.webp'
      )
    end

    # O asset_host aponta para um CDN; a rota precisa do domínio da rede para achar a entidade.
    it 'keeps the entity domain when an asset host is configured' do
      logo = double(blank?: false, identifier: 'brasao.webp')
      original_asset_host = helper.config.asset_host
      helper.config.asset_host = 'https://cdn.example.com'

      begin
        image = helper.image_tag(helper.entity_logo_url_for(double(logo: logo)))
      ensure
        helper.config.asset_host = original_asset_host
      end

      expect(image).to include('src="http://test.host/entity_logo?v=brasao.webp"')
    end

    it 'returns nil when there is no logo' do
      expect(helper.entity_logo_url_for(EntityConfiguration.new)).to be_nil
      expect(helper.entity_logo_url_for(nil)).to be_nil
    end
  end

  describe '#logo_url' do
    let(:entity_configuration) { double(logo: double(blank?: false, identifier: 'brasao.webp')) }

    before do
      allow(helper).to receive(:current_entity_configuration).and_return(entity_configuration)
    end

    it 'uses the logo route in production' do
      allow(Rails.env).to receive(:production?).and_return(true)

      expect(helper.send(:logo_url)).to eq('http://test.host/entity_logo?v=brasao.webp')
    end

    it 'falls back to the default logo when the entity has none' do
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(helper).to receive(:current_entity_configuration).and_return(nil)

      expect(helper.send(:logo_url)).to eq(ApplicationHelper::DEFAULT_LOGO)
    end

    it 'uses the default logo outside production' do
      expect(helper.send(:logo_url)).to eq(ApplicationHelper::DEFAULT_LOGO)
    end
  end
end
