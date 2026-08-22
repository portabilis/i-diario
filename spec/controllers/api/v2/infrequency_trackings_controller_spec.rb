require 'rails_helper'

RSpec.describe Api::V2::InfrequencyTrackingsController, type: :controller do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity, api_code: 'unity-1') }
  let(:course) { create(:course) }
  let(:grade) { create(:grade, course: course) }
  let(:classroom) { create(:classroom, unity: unity, year: year) }
  let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }
  let(:api_token) { SecureRandom.hex(15) }
  let(:period) { { unity_api_code: unity.api_code, start_at: '2026-06-01', end_at: '2026-06-30' } }

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
    it 'returns 401 without a valid token' do
      request.headers['token'] = 'invalid'

      get :index, params: { format: :json, locale: 'en' }.merge(period)

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 422 when the period or the unity is missing' do
      get :index, params: { format: :json, locale: 'en' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to include('unity_api_code', 'start_at', 'end_at')
    end

    it 'exposes the api_codes and the absence dates behind each notification' do
      student = create(:student, api_code: '777')
      student_enrollment = create(:student_enrollment, student: student, api_code: '999')
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade
      )

      create(
        :infrequency_tracking,
        student: student,
        classroom: classroom,
        notification_date: '2026-06-10',
        notification_type: InfrequencyTrackingTypes::CONSECUTIVE_ABSENCES,
        notification_data: [{ teacher_id: 1, absences: %w[2026-06-03 2026-06-01 2026-06-02] }]
      )

      get :index, params: { format: :json, locale: 'en' }.merge(period)

      expect(response).to have_http_status(:success)

      row = JSON.parse(response.body).find { |item| item['student_api_code'] == '777' }

      expect(row).to be_present
      expect(row['notification_type']).to eq('consecutive_absences')
      expect(row['registration_api_code']).to eq('999') # ref_cod_matricula do i-Educar
      expect(row['classroom_api_code']).to eq(classroom.api_code)
      expect(row['unity_api_code']).to eq('unity-1')
      # Ordenadas: quem consome agrupa as datas em episódios de afastamento.
      expect(row['absence_dates']).to eq(%w[2026-06-01 2026-06-02 2026-06-03])
      expect(row['absences_count']).to eq(3)
    end

    it 'counts a day once when more than one teacher registered the absence' do
      student = create(:student, api_code: 'dup')

      create(
        :infrequency_tracking,
        student: student,
        classroom: classroom,
        notification_date: '2026-06-10',
        notification_data: [
          { teacher_id: 1, absences: %w[2026-06-01 2026-06-02] },
          { teacher_id: 2, absences: %w[2026-06-02] }
        ]
      )

      get :index, params: { format: :json, locale: 'en' }.merge(period)

      row = JSON.parse(response.body).find { |item| item['student_api_code'] == 'dup' }

      expect(row['absence_dates']).to eq(%w[2026-06-01 2026-06-02])
      expect(row['absences_count']).to eq(2)
    end

    it 'keeps only the notifications inside the period' do
      create(
        :infrequency_tracking,
        student: create(:student, api_code: 'before'),
        classroom: classroom,
        notification_date: '2026-05-20'
      )
      create(
        :infrequency_tracking,
        student: create(:student, api_code: 'inside'),
        classroom: classroom,
        notification_date: '2026-06-15'
      )

      get :index, params: { format: :json, locale: 'en' }.merge(period)

      codes = JSON.parse(response.body).map { |item| item['student_api_code'] }

      expect(codes).to include('inside')
      expect(codes).not_to include('before')
    end

    it 'keeps only the notifications of the requested unity' do
      other_classroom = create(:classroom, unity: create(:unity, api_code: 'unity-2'), year: year)

      create(
        :infrequency_tracking,
        student: create(:student, api_code: 'mine'),
        classroom: classroom,
        notification_date: '2026-06-15'
      )
      create(
        :infrequency_tracking,
        student: create(:student, api_code: 'theirs'),
        classroom: other_classroom,
        notification_date: '2026-06-15'
      )

      get :index, params: { format: :json, locale: 'en' }.merge(period)

      codes = JSON.parse(response.body).map { |item| item['student_api_code'] }

      expect(codes).to include('mine')
      expect(codes).not_to include('theirs')
    end
  end
end
