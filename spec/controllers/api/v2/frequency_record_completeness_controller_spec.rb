require 'rails_helper'

RSpec.describe Api::V2::FrequencyRecordCompletenessController, type: :controller do
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:classroom) { create(:classroom, unity: unity, year: 2026) }
  let(:api_token) { SecureRandom.hex(15) }
  let(:period) { { unity_api_code: unity.api_code, start_at: '2026-06-01', end_at: '2026-06-30' } }

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  before do
    IeducarApiConfiguration.current.update!(
      url: 'http://test.ieducar.com.br',
      token: '8IOwGIjiHvbeTklgwo10yVLgwDhhvs',
      secret_token: '5y8cfq31oGvFdAlGMCLIeSKdfc8pUC',
      unity_code: 1,
      api_security_token: api_token
    )
    request.headers['token'] = api_token
  end

  describe 'GET #index' do
    it 'returns 401 without a valid token' do
      request.headers['token'] = 'invalid'

      get :index, params: { format: :json }.merge(period)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when the period or the unity is missing' do
      get :index, params: { format: :json }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'counts the school days of the unity and the days the classroom recorded' do
      %w[2026-06-01 2026-06-02 2026-06-03].each do |day|
        create(:unity_school_day, unity: unity, school_day: day)
      end

      # Duas disciplinas no mesmo dia contam UM dia com registro.
      create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-01')
      create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-01')
      create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-02')

      get :index, params: { format: :json }.merge(period)

      expect(response).to have_http_status(:success)

      row = JSON.parse(response.body).find { |item| item['classroom_api_code'] == classroom.api_code }

      expect(row['school_days']).to eq(3)
      expect(row['days_with_record']).to eq(2)
    end

    # A turma que nunca lançou é justamente a que o indicador existe para
    # mostrar: ela entra na lista com zero, nunca desaparece.
    it 'keeps a classroom that never recorded, with zero' do
      create(:unity_school_day, unity: unity, school_day: '2026-06-01')
      classroom

      get :index, params: { format: :json }.merge(period)

      row = JSON.parse(response.body).find { |item| item['classroom_api_code'] == classroom.api_code }

      expect(row).to be_present
      expect(row['days_with_record']).to eq(0)
      expect(row['school_days']).to eq(1)
    end

    it 'ignores classrooms of other unities' do
      other_classroom = create(:classroom, unity: create(:unity, api_code: 'unity-2'), year: 2026)
      classroom

      get :index, params: { format: :json }.merge(period)

      codes = JSON.parse(response.body).map { |item| item['classroom_api_code'] }

      expect(codes).to include(classroom.api_code)
      expect(codes).not_to include(other_classroom.api_code)
    end
  end
end
