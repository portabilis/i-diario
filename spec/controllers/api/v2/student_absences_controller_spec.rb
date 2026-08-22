require 'rails_helper'

RSpec.describe Api::V2::StudentAbsencesController, type: :controller do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:classroom) { create(:classroom, unity: unity, year: year) }
  let(:student) { create(:student, api_code: '777') }
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

  # A justificativa não tem associação declarada no model: o vínculo é a
  # própria coluna, e é a presença dela que define "falta justificada".
  def absence_on(date, justified: false, student: nil)
    daily_frequency = create(:daily_frequency, classroom: classroom, frequency_date: date)
    justification = justified ? create(:absence_justifications_student, student: student) : nil

    create(
      :daily_frequency_student,
      daily_frequency: daily_frequency,
      student: student,
      present: false,
      absence_justification_student_id: justification&.id
    )
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

    it 'separates the entries with a justification from the ones without it' do
      absence_on('2026-06-10', justified: true, student: student)
      absence_on('2026-06-10', student: student)
      absence_on('2026-06-11', student: student)

      get :index, params: { format: :json }.merge(period)

      expect(response).to have_http_status(:success)

      row = JSON.parse(response.body).find { |item| item['student_api_code'] == '777' }

      # O dia 10 teve duas faltas lançadas e só uma justificada: o fato vai
      # cru, porque a régua de "dia justificado" é de quem lê.
      expect(row['absences']).to eq(
        [
          { 'date' => '2026-06-10', 'entries_count' => 2, 'justified_entries_count' => 1 },
          { 'date' => '2026-06-11', 'entries_count' => 1, 'justified_entries_count' => 0 }
        ]
      )
    end

    it 'ignores presences and days outside the period' do
      absence_on('2026-05-20', student: student)

      daily_frequency = create(:daily_frequency, classroom: classroom, frequency_date: '2026-06-12')
      create(:daily_frequency_student, daily_frequency: daily_frequency, student: student, present: true)

      get :index, params: { format: :json }.merge(period)

      expect(JSON.parse(response.body)).to be_empty
    end

    it 'keeps only the absences of the requested unity' do
      other_classroom = create(:classroom, unity: create(:unity, api_code: 'unity-2'), year: year)
      other_frequency = create(:daily_frequency, classroom: other_classroom, frequency_date: '2026-06-10')
      create(
        :daily_frequency_student,
        daily_frequency: other_frequency,
        student: create(:student, api_code: 'theirs'),
        present: false
      )
      absence_on('2026-06-10', student: student)

      get :index, params: { format: :json }.merge(period)

      codes = JSON.parse(response.body).map { |item| item['student_api_code'] }

      expect(codes).to eq(['777'])
    end
  end
end
