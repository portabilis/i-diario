require 'rails_helper'

RSpec.describe Api::V2::MonthlyFrequenciesController, type: :controller do
  let(:year) { 2026 }
  let(:months) { [3, 4] }
  let(:classroom_api_code) { '001' }
  let(:api_token) { SecureRandom.hex(15) }
  let(:service_payload) do
    [
      {
        classroom_id: classroom_api_code,
        classroom_name: 'Turma A',
        year: year,
        months: [{ month: 3, students: [] }, { month: 4, students: [] }]
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

      get :index, params: { classrooms: [classroom_api_code], year: year, months: months, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when classrooms is missing' do
      get :index, params: { year: year, months: months, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('classrooms')
    end

    it 'returns 422 when year is missing' do
      get :index, params: { classrooms: [classroom_api_code], months: months, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('year')
    end

    it 'returns 422 when months is missing' do
      get :index, params: { classrooms: [classroom_api_code], year: year, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'returns 422 when any month is out of range' do
      get :index, params: { classrooms: [classroom_api_code], year: year, months: [3, 13], format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'returns 422 when months contains zero' do
      get :index, params: { classrooms: [classroom_api_code], year: year, months: [0], format: 'json', locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('months')
    end

    it 'accepts a single month and returns 200' do
      allow(Api::MonthlyFrequenciesService).to receive(:call).and_return(service_payload)

      get :index, params: { classrooms: [classroom_api_code], year: year, months: [3], format: 'json', locale: 'en' }

      expect(response).to have_http_status(:ok)
    end

    it 'delegates to the service and renders its result as JSON' do
      allow(Api::MonthlyFrequenciesService).to receive(:call).and_return(service_payload)

      get :index, params: { classrooms: [classroom_api_code], year: year, months: months, format: 'json', locale: 'en' }

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to be_an(Array)
      expect(body.first['classroom_id']).to eq(classroom_api_code)
      expect(body.first['months'].map { |m| m['month'] }).to eq([3, 4])
    end

    it 'passes student_ids to the service when provided' do
      expect(Api::MonthlyFrequenciesService).to receive(:call).with(
        hash_including(students_api_code: %w[999 888])
      ).and_return(service_payload)

      get :index, params: {
        classrooms: [classroom_api_code],
        year: year,
        months: months,
        student_ids: %w[999 888],
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:ok)
    end
  end
end
