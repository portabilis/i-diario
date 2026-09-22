require 'rails_helper'

RSpec.describe ExamRecordReportController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  let(:teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:teacher_discipline) { create(:discipline, description: 'Matemática') }
  let(:other_discipline) { create(:discipline, description: 'Arte') }
  let(:school_calendar) { create(:school_calendar, :with_trimester_steps, unity: unity) }

  let(:classroom) do
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      teacher: teacher,
      discipline: teacher_discipline,
      school_calendar: school_calendar,
      year: school_calendar.year,
      unity: unity
    )
  end

  let(:other_classroom) do
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      teacher: other_teacher,
      discipline: other_discipline,
      school_calendar: school_calendar,
      year: school_calendar.year,
      unity: unity
    )
  end

  let(:admin_user) do
    create(
      :user,
      :with_user_role_administrator,
      assumed_teacher_id: teacher.id,
      current_unity_id: unity.id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: teacher_discipline.id
    )
  end

  before do
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: other_discipline,
      teacher: other_teacher,
      year: classroom.year
    )

    sign_in(admin_user)
    allow(controller).to receive(:current_school_year).and_return(classroom.year)
  end

  def response_ids(key)
    JSON.parse(response.body)[key].map { |element| element['id'] }
  end

  describe 'GET #form' do
    it 'lists only the unities where the profile teacher has classrooms' do
      create(
        :classroom,
        :with_teacher_discipline_classroom,
        teacher: other_teacher,
        discipline: other_discipline,
        unity: create(:unity)
      )

      get :form, params: { locale: 'pt-BR' }

      expect(response).to have_http_status(:ok)
      expect(assigns(:unities)).to eq([unity])
    end

    context 'when the user is not an administrator' do
      let(:employee_user) do
        create(
          :user,
          :with_user_role_administrator,
          admin: false,
          assumed_teacher_id: teacher.id,
          current_unity_id: unity.id,
          current_school_year: classroom.year,
          current_classroom_id: classroom.id,
          current_discipline_id: teacher_discipline.id
        )
      end

      it 'lists the unity of the profile, which is the only one the user can use' do
        create(
          :classroom,
          :with_teacher_discipline_classroom,
          teacher: teacher,
          discipline: teacher_discipline,
          unity: create(:unity)
        )
        sign_in(employee_user)

        get :form, params: { locale: 'pt-BR' }

        expect(assigns(:unities)).to eq([unity])
      end
    end
  end

  describe 'GET #classrooms' do
    it 'returns only the classrooms of the profile teacher in the unity' do
      other_classroom

      get :classrooms, params: { locale: 'pt-BR', format: 'json', unity_id: unity.id }

      expect(response).to have_http_status(:ok)
      expect(response_ids('classrooms')).to eq([classroom.id])
    end

    it 'returns an empty list when the unity is blank' do
      get :classrooms, params: { locale: 'pt-BR', format: 'json', unity_id: '' }

      expect(response_ids('classrooms')).to eq([])
    end
  end

  describe 'GET #disciplines' do
    it 'returns only the disciplines the profile teacher teaches in the classroom' do
      get :disciplines, params: { locale: 'pt-BR', format: 'json', classroom_id: classroom.id }

      expect(response).to have_http_status(:ok)
      expect(response_ids('disciplines')).to eq([teacher_discipline.id])
    end

    it 'returns the disciplines ordered by description' do
      second_discipline = create(:discipline, description: 'Ciências')
      create(
        :teacher_discipline_classroom,
        classroom: classroom,
        discipline: second_discipline,
        teacher: teacher,
        year: classroom.year
      )

      get :disciplines, params: { locale: 'pt-BR', format: 'json', classroom_id: classroom.id }

      expect(response_ids('disciplines')).to eq([second_discipline.id, teacher_discipline.id])
    end

    it 'returns an empty list when the classroom is blank' do
      get :disciplines, params: { locale: 'pt-BR', format: 'json', classroom_id: '' }

      expect(response_ids('disciplines')).to eq([])
    end

    context 'when the user has the teacher role' do
      let(:teacher_user) do
        create(
          :user,
          :with_user_role_teacher,
          teacher_id: teacher.id,
          current_unity_id: unity.id,
          current_school_year: classroom.year,
          current_classroom_id: classroom.id,
          current_discipline_id: teacher_discipline.id
        )
      end

      before { sign_in(teacher_user) }

      it 'returns only the disciplines the teacher teaches in the classroom' do
        get :disciplines, params: { locale: 'pt-BR', format: 'json', classroom_id: classroom.id }

        expect(response_ids('disciplines')).to eq([teacher_discipline.id])
      end
    end
  end

  describe 'POST #report' do
    def post_report(discipline)
      post :report, params: {
        locale: 'pt-BR',
        exam_record_report_form: {
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          school_calendar_step_id: school_calendar.steps.first.id
        }
      }
    end

    it 'rejects a discipline the profile teacher does not teach in the classroom' do
      post_report(other_discipline)

      expect(response).to render_template(:form)
      expect(assigns(:exam_record_report_form).errors[:discipline_id]).to(
        include('não é lecionada pelo professor do perfil nesta turma')
      )
    end

    it 'accepts a discipline the profile teacher teaches in the classroom' do
      post_report(teacher_discipline)

      expect(assigns(:exam_record_report_form).errors[:discipline_id]).to be_empty
    end
  end
end
