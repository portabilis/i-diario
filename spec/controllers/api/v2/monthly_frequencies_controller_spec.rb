require 'rails_helper'

RSpec.describe Api::V2::MonthlyFrequenciesController, type: :controller do
  let(:enrollment_api_codes) { %w[EN001 EN002] }
  let(:months) { [3, 4] }
  let(:api_token) { SecureRandom.hex(15) }
  let(:service_payload) do
    [
      {
        course_name: 'Ensino Fundamental',
        student_enrollment_id: 'EN001',
        student_name: 'Ana',
        months: { 3 => 90.0, 4 => 85.0 }
      }
    ]
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
      request.env['REQUEST_PATH'] = '/api/v2/monthly_frequencies'
    end

    it 'returns 401 without valid token' do
      request.headers['token'] = 'invalid_token'

      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: months,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when student_enrollment_ids is missing' do
      get :index, params: { months: months, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('student_enrollment_ids')
    end

    it 'returns 422 when months is missing' do
      get :index, params: { student_enrollment_ids: enrollment_api_codes, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'returns 422 when any month is out of range' do
      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: [3, 13],
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'returns 422 when months contains zero' do
      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: [0],
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'accepts a single month and returns 200' do
      allow(Api::MonthlyFrequenciesService).to receive(:call).and_return(service_payload)

      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: [3],
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:ok)
    end

    it 'delegates to the service and renders its result as JSON' do
      allow(Api::MonthlyFrequenciesService).to receive(:call).and_return(service_payload)

      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: months,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first['course_name']).to eq('Ensino Fundamental')
      expect(body.first['student_enrollment_id']).to eq('EN001')
      # months vira hash com chave string em JSON
      expect(body.first['months']).to eq('3' => 90.0, '4' => 85.0)
    end

    it 'passes student_enrollment_ids as student_enrollment_api_code to the service' do
      expect(Api::MonthlyFrequenciesService).to receive(:call).with(
        hash_including(student_enrollment_api_code: enrollment_api_codes)
      ).and_return(service_payload)

      get :index, params: {
        student_enrollment_ids: enrollment_api_codes,
        months: months,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:ok)
    end
  end
end
