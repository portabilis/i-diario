require 'rails_helper'

RSpec.describe EntityLogosController, type: :controller do
  include_context 'entity logo storage'

  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:entity_configuration) { EntityConfiguration.create! }

  around do |example|
    entity.using_connection { example.run }
  end

  def upload_logo
    File.open(build_logo_image('brasao.png')) { |file| entity_configuration.update!(logo: file) }
    entity_configuration.reload
  end

  describe 'GET #show' do
    context 'when the entity has a logo' do
      before { upload_logo }

      it 'serves the WebP logo without requiring login' do
        get :show, params: { v: entity_configuration.logo.identifier }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('image/webp')
        expect(response.body.b).to eq(File.binread(entity_configuration.logo.path))
      end

      it 'lets the browser cache the current version for a year' do
        get :show, params: { v: entity_configuration.logo.identifier }

        expect(response.headers['Cache-Control']).to eq("max-age=#{1.year.to_i}, public")
      end

      it 'does not let the browser keep an outdated version' do
        get :show, params: { v: 'brasao-anterior.webp' }

        expect(response).to have_http_status(:ok)
        expect(response.headers['Cache-Control']).not_to include('public')
      end
    end

    it 'responds not found when the entity has no logo' do
      entity_configuration

      get :show

      expect(response).to have_http_status(:not_found)
    end

    it 'responds not found for a host without entity' do
      request.host = 'unknown.host'

      get :show

      expect(response).to have_http_status(:not_found)
    end
  end
end
