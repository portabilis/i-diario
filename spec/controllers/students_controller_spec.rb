require 'spec_helper'

RSpec.describe StudentsController, type: :controller do

  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) do
    create(
      :user_with_user_role,
      admin: false,
      teacher_id: current_teacher.id,
      current_unity_id: unity.id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end
  let(:user_role) { user.user_roles.first }
  let(:unity) { create(:unity) }
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, opened_year: true) }

  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_trimester_steps,
      :score_type_numeric,
      unity: unity,
      teacher: current_teacher,
      discipline: discipline,
      school_calendar: school_calendar
    )
  }

  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom) }

  let!(:student_enrollment_classroom) {
    create(
      :student_enrollment_classroom,
      classrooms_grade: classrooms_grade,
      joined_at: '2017-01-01',
      left_at: ''
    )
  }

  let(:params) {
    {
      locale: 'pt-BR',
      classroom_id: classroom.id,
      discipline_id: discipline.id,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC
    }
  }

  let(:params_with_date) {
    {
      locale: 'pt-BR',
      classroom_id: classroom.id,
      discipline_id: discipline.id,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC
    }
  }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #index' do
    it 'returns students when params are correct, not including dates' do
      get :index, params: params
      expect(response.body).to include(student_enrollment_classroom.student_enrollment.student.id.to_s)
    end

    it 'returns students when params are correct, including dates' do
      get :index, params: params_with_date
      expect(response.body).to include(student_enrollment_classroom.student_enrollment.student.id.to_s)
    end
  end

end
