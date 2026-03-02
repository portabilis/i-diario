require 'rails_helper'

RSpec.describe Api::V2::DisciplineRecordsController, type: :controller do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity) }
  let(:course) { create(:course) }
  let(:grade) { create(:grade, course: course) }
  let(:discipline) { create(:discipline) }
  let(:classroom) do
    create(:classroom, :with_classroom_semester_steps, unity: unity, year: year)
  end
  let!(:classrooms_grade) do
    create(:classrooms_grade, classroom: classroom, grade: grade)
  end
  let(:api_token) { SecureRandom.hex(15) }

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

  describe 'POST #count' do
    before do
      request.env['REQUEST_PATH'] = '/api/v2/discipline_records/count'
    end

    it 'returns 401 without valid token' do
      request.headers['token'] = 'invalid_token'

      post :count, params: { year: year, format: 'json', locale: 'en' }, xhr: true

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 without year parameter' do
      post :count, params: { format: 'json', locale: 'en' }, xhr: true

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'returns counts with all filters' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      params = {
        year: year,
        unities: [unity.api_code],
        courses: [course.api_code],
        grades: [grade.api_code],
        disciplines: [discipline.api_code],
        format: 'json',
        locale: 'en'
      }

      post :count, params: params, xhr: true

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json).to be_an(Array)
      expect(json.size).to eq(11)

      frequency_entry = json.find { |e| e['label'] == 'Frequências diárias' }
      expect(frequency_entry['count']).to eq(1)
    end

    it 'returns zeros when no records match' do
      params = {
        year: year,
        unities: [unity.api_code],
        disciplines: [discipline.api_code],
        format: 'json',
        locale: 'en'
      }

      post :count, params: params, xhr: true

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.all? { |e| e['count'] == 0 }).to be true
    end
  end

  describe 'POST #destroy_batch' do
    before do
      request.env['REQUEST_PATH'] = '/api/v2/discipline_records/destroy_batch'
    end

    it 'returns 401 without valid token' do
      request.headers['token'] = 'invalid_token'

      post :destroy_batch, params: { year: year, format: 'json', locale: 'en' }, xhr: true

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 without year parameter' do
      post :destroy_batch, params: { format: 'json', locale: 'en' }, xhr: true

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['success']).to be false
    end

    it 'destroys matching records and returns total' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      params = {
        year: year,
        unities: [unity.api_code],
        disciplines: [discipline.api_code],
        format: 'json',
        locale: 'en'
      }

      expect {
        post :destroy_batch, params: params, xhr: true
      }.to change(DailyFrequency, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['deleted']).to be > 0
    end

    it 'does not destroy records from other disciplines' do
      other_discipline = create(:discipline)

      create(
        :daily_frequency,
        classroom: classroom,
        discipline: other_discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      params = {
        year: year,
        unities: [unity.api_code],
        disciplines: [discipline.api_code],
        format: 'json',
        locale: 'en'
      }

      expect {
        post :destroy_batch, params: params, xhr: true
      }.not_to change(DailyFrequency, :count)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['deleted']).to eq(0)
    end
  end
end
