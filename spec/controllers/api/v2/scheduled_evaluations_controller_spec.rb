require 'rails_helper'

RSpec.describe Api::V2::ScheduledEvaluationsController, type: :controller do
  let(:api_token) { SecureRandom.hex(15) }
  let(:service_payload) do
    {
      data: [
        {
          id: 1,
          type: 'numerical_exam',
          date: '2026-06-10',
          title: 'Prova',
          discipline: { id: 'DISC001', name: 'Matemática' },
          step: { number: 1, name: '1º Bimestre', start_at: '2026-01-01', end_at: '2026-03-31' },
          score_type: 'numeric',
          maximum_score: 10.0
        }
      ],
      meta: { classroom_id: 'CLS001', year: 2026, step_number: nil }
    }
  end

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  before do
    ieducar_config = IeducarApiConfiguration.current
    ieducar_config.update!(
      url: 'http://test.ieducar.com.br',
      token: '8IOwGIjiHvbeTklgwo10yVLgwDhhvs',
      secret_token: '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC',
      unity_code: 1,
      api_security_token: api_token
    )
    request.headers['token'] = api_token
  end

  describe 'GET #index' do
    before do
      request.env['REQUEST_PATH'] = '/api/v2/scheduled_evaluations'
    end

    it 'returns 401 without valid token' do
      request.headers['token'] = 'invalid_token'

      get :index, params: { classroom_id: 'CLS001', year: 2026, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when classroom_id is missing' do
      get :index, params: { year: 2026, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('classroom_id')
    end

    it 'returns 422 when year is missing' do
      get :index, params: { classroom_id: 'CLS001', format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('year')
    end

    it 'delegates to the service and renders its result as JSON' do
      allow(Api::ListScheduledEvaluationsByClassroomService).to receive(:call).and_return(service_payload)

      get :index, params: { classroom_id: 'CLS001', year: 2026, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['data'].first['type']).to eq('numerical_exam')
      expect(body['meta']['classroom_id']).to eq('CLS001')
    end

    it 'passes classroom_id, year, step_number, discipline_id and after_date to the service' do
      expect(Api::ListScheduledEvaluationsByClassroomService).to receive(:call).with(
        classroom_api_code: 'CLS001',
        year: '2026',
        step_number: '2',
        discipline_api_code: 'DISC001',
        after_date: '2026-03-01'
      ).and_return(service_payload)

      get :index, params: {
        classroom_id: 'CLS001',
        year: '2026',
        step_number: '2',
        discipline_id: 'DISC001',
        after_date: '2026-03-01',
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:ok)
    end
  end
end
