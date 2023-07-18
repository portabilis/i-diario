require 'spec_helper'

RSpec.describe DailyFrequenciesController, type: :controller do
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
  let(:grade) { create(:grade) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_trimester_steps,
      :score_type_numeric,
      unity: unity,
      teacher: current_teacher,
      grade: grade,
      discipline: discipline,
      school_calendar: school_calendar
    )
  }

  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }

  let(:params) {
    {
      locale: 'pt-BR',
      class_numbers: '1, 2',
      daily_frequency: {
        classroom_id: classroom.id,
        unity_id: unity.id,
        discipline_id: discipline.id,
        frequency_date: '2017-02-28',
        period: 1
      }
    }
  }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    user_role.unity = unity
    user_role.save!

    user.current_user_role = user_role
    user.save!

    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user_is_employee_or_administrator?).and_return(false)
    allow(controller).to receive(:can_change_school_year?).and_return(true)
    allow(controller).to receive(:current_classroom).and_return(classroom)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_school_calendar).and_return(school_calendar)
    allow(controller).to receive(:current_teacher_id).and_return(current_teacher.id)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'POST #create' do
    context 'without success' do
      it 'fails to create and renders the new template' do
        allow(school_calendar).to receive(:day_allows_entry?).and_return(false)
        post :create, params: params
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to daily frequency edit page' do
        post :create, params: params
        expect(response).to redirect_to /#{edit_multiple_daily_frequencies_path}/
      end
    end
  end

  describe 'GET #edit_multiple' do
    before do
      allow(controller).to receive(:discipline_classroom_grade_ids).and_return([1, 2, classrooms_grade.grade_id])
    end

    context 'without success' do
      it 'returns not found status' do
        get :edit_multiple, params: params
        expect(response).to have_http_status(302)
      end
    end

    context 'with success' do
      it 'returns success status' do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade)
        params[:class_numbers] = [1, 2, classrooms_grade.grade_id]
        get :edit_multiple, params: params
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'DELETE #destroy_multiple' do
    let!(:daily_frequency_1) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }
    let!(:daily_frequency_2) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }
    let!(:daily_frequency_3) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }

    shared_examples 'delete_all_frequencies' do
      it 'deletes all daily_frequencies and daily_frequency_students' do
        daily_frequencies_ids = [daily_frequency_1.id, daily_frequency_2.id]

        expect {
          delete :destroy_multiple, params: { locale: 'pt-BR', daily_frequencies_ids: daily_frequencies_ids }
        }.to change(DailyFrequency, :count).by(-2)
      end
    end

    context 'when just has daily_frequencies and daily_frequency_students' do
      it_behaves_like 'delete_all_frequencies'
    end

    context 'when has discarded daily_frequency_students' do
      before do
        daily_frequency_1.students.last.discard
      end

      it_behaves_like 'delete_all_frequencies'
    end
  end
end
