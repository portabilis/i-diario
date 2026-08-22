require 'rails_helper'

RSpec.describe Api::V2::UnitySchoolDaysController, type: :controller do
  let(:unity) { create(:unity, api_code: 'unity-1') }
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

    it 'lists the school days of the unity in ascending order' do
      create(:unity_school_day, unity: unity, school_day: '2026-06-03')
      create(:unity_school_day, unity: unity, school_day: '2026-06-01')
      create(:unity_school_day, unity: unity, school_day: '2026-06-02')

      get :index, params: { format: :json }.merge(period)

      expect(response).to have_http_status(:success)

      expect(JSON.parse(response.body)).to eq(
        [
          {
            'unity_api_code' => 'unity-1',
            'school_days' => %w[2026-06-01 2026-06-02 2026-06-03]
          }
        ]
      )
    end

    it 'ignores days outside the period and of other unities' do
      other_unity = create(:unity, api_code: 'unity-2')

      create(:unity_school_day, unity: unity, school_day: '2026-06-10')
      create(:unity_school_day, unity: unity, school_day: '2026-05-20')
      create(:unity_school_day, unity: other_unity, school_day: '2026-06-10')

      get :index, params: { format: :json }.merge(period)

      body = JSON.parse(response.body)

      expect(body.size).to eq(1)
      expect(body.first['unity_api_code']).to eq('unity-1')
      expect(body.first['school_days']).to eq(['2026-06-10'])
    end
  end
end
