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

  # O dia consolidado é o que o motor de infrequência enxerga.
  def consolidate(date, present:, student:)
    create(
      :unique_daily_frequency_student,
      student: student,
      classroom: classroom,
      frequency_date: date,
      present: present
    )
  end

  # O lançamento do diário: é nele que a justificativa se prende (a coluna é o
  # vínculo; o model não declara associação).
  def entry(date, student:, justified: false)
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

    it 'reports how many entries of the day carry a justification' do
      consolidate('2026-06-10', present: false, student: student)
      entry('2026-06-10', student: student, justified: true)
      entry('2026-06-10', student: student)

      consolidate('2026-06-11', present: false, student: student)
      entry('2026-06-11', student: student)

      get :index, params: { format: :json }.merge(period)

      expect(response).to have_http_status(:success)

      row = JSON.parse(response.body).find { |item| item['student_api_code'] == '777' }

      expect(row['absences']).to eq(
        [
          { 'date' => '2026-06-10', 'entries_count' => 2, 'justified_entries_count' => 1 },
          { 'date' => '2026-06-11', 'entries_count' => 1, 'justified_entries_count' => 0 }
        ]
      )
    end

    # A regra do produto de origem: o dia consolidado manda. Se ele fechou como
    # presente, o dia não é falta aqui — mesmo havendo falta numa aula solta.
    it 'ignores a day that consolidated as present even with an absent entry' do
      consolidate('2026-06-12', present: true, student: student)
      entry('2026-06-12', student: student)

      get :index, params: { format: :json }.merge(period)

      expect(JSON.parse(response.body)).to be_empty
    end

    it 'ignores days outside the period' do
      consolidate('2026-05-20', present: false, student: student)
      entry('2026-05-20', student: student)

      get :index, params: { format: :json }.merge(period)

      expect(JSON.parse(response.body)).to be_empty
    end

    it 'keeps only the absences of the requested unity' do
      other_classroom = create(:classroom, unity: create(:unity, api_code: 'unity-2'), year: year)
      create(
        :unique_daily_frequency_student,
        student: create(:student, api_code: 'theirs'),
        classroom: other_classroom,
        frequency_date: '2026-06-10',
        present: false
      )

      consolidate('2026-06-10', present: false, student: student)
      entry('2026-06-10', student: student)

      get :index, params: { format: :json }.merge(period)

      codes = JSON.parse(response.body).map { |item| item['student_api_code'] }

      expect(codes).to eq(['777'])
    end
  end
end
