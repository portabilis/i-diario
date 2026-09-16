require 'rails_helper'

RSpec.describe Api::V2::EnrollmentDailyFrequencyStatusesController, type: :controller do
  let(:enrollment_api_code) { 'EN001' }
  let(:api_token) { SecureRandom.hex(15) }
  let(:service_payload) do
    {
      '2026-03-02' => 'presence',
      '2026-03-03' => 'absent',
      '2026-03-04' => 'justified'
    }
  end
  let(:valid_params) do
    {
      student_enrollment_id: enrollment_api_code,
      start_at: '2026-03-01',
      end_at: '2026-03-31',
      format: 'json',
      locale: 'en'
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
      request.env['REQUEST_PATH'] = '/api/v2/enrollment_daily_frequency_statuses'
    end

    it 'returns 401 without valid token' do
      request.headers['token'] = 'invalid_token'

      get :index, params: valid_params

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when student_enrollment_id is missing' do
      get :index, params: valid_params.except(:student_enrollment_id)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('student_enrollment_id')
    end

    it 'returns 200 without start_at and end_at, delegating nil dates to the service' do
      expect(Api::EnrollmentDailyFrequencyStatusesService).to receive(:call).with(
        student_enrollment_api_code: enrollment_api_code,
        start_at: nil,
        end_at: nil
      ).and_return(service_payload)

      get :index, params: valid_params.except(:start_at, :end_at)

      expect(response).to have_http_status(:ok)
    end

    it 'returns 200 when only start_at is given' do
      expect(Api::EnrollmentDailyFrequencyStatusesService).to receive(:call).with(
        student_enrollment_api_code: enrollment_api_code,
        start_at: Date.new(2026, 3, 1),
        end_at: nil
      ).and_return(service_payload)

      get :index, params: valid_params.except(:end_at)

      expect(response).to have_http_status(:ok)
    end

    it 'returns 422 when start_at is not an ISO 8601 date' do
      get :index, params: valid_params.merge(start_at: '01/02/2026')

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('AAAA-MM-DD')
    end

    it 'returns 422 when end_at is not a valid date' do
      get :index, params: valid_params.merge(end_at: '2026-13-01')

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('AAAA-MM-DD')
    end

    it 'returns 422 when start_at is after end_at' do
      get :index, params: valid_params.merge(start_at: '2026-04-01', end_at: '2026-03-01')

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('start_at')
    end

    it 'delegates to the service and renders its result as JSON' do
      expect(Api::EnrollmentDailyFrequencyStatusesService).to receive(:call).with(
        student_enrollment_api_code: enrollment_api_code,
        start_at: Date.new(2026, 3, 1),
        end_at: Date.new(2026, 3, 31)
      ).and_return(service_payload)

      get :index, params: valid_params

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(service_payload)
    end

    it 'returns 404 when the enrollment is not found' do
      allow(Api::EnrollmentDailyFrequencyStatusesService).to receive(:call)
        .and_raise(ActiveRecord::RecordNotFound)

      get :index, params: valid_params

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)['message']).to eq('Elemento não encontrado')
    end
  end
end
