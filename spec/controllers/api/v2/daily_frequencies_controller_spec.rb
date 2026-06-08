require 'rails_helper'

RSpec.describe Api::V2::DailyFrequenciesController, type: :controller do
  around(:each) do |example|
    Entity.find_by_domain("test.host").using_connection do
      example.run
    end
  end

  before do
    allow(controller).to receive(:authenticate_api!)
  end

  describe 'POST #create' do
    context 'when classroom_id does not exist' do
      it 'returns not found json response' do
        params = {
          classroom_id: 0,
          discipline_id: 1,
          frequency_date: '2026-03-27',
          teacher_id: 1,
          format: 'json',
          locale: 'en'
        }

        post :create, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'GET #index' do
    context 'when classroom_id does not exist' do
      it 'returns not found json response' do
        params = {
          classroom_id: 0,
          format: 'json',
          locale: 'en'
        }

        get :index, params: params, xhr: true

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to include('application/json')
      end
    end
  end
end
