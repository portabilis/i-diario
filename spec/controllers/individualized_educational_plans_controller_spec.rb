require 'rails_helper'

RSpec.describe IndividualizedEducationalPlansController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  around(:each) do |example|
    entity.using_connection { example.run }
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:require_current_teacher).and_return(true)
  end

  describe 'GET #index' do
    context 'as an admin/employee' do
      let(:classroom) { create(:classroom) }

      before { allow(controller).to receive(:current_user_classroom).and_return(classroom) }

      it 'lists only plans of the selected classroom' do
        target = create(:individualized_educational_plan, classroom: classroom)
        create(:individualized_educational_plan) # plano em outra turma, deve ser excluído

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'filters by student' do
        target = create(:individualized_educational_plan, classroom: classroom)
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR', filter: { by_student_id: target.student_id } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'paginates the plans (default 10 per page)' do
        create_list(:individualized_educational_plan, 11, classroom: classroom)

        get :index, params: { locale: 'pt-BR', page: 2 }

        expect(assigns(:individualized_educational_plans).to_a.size).to eq(1)
      end
    end

    context 'without a classroom selected in the profile' do
      before { allow(controller).to receive(:current_user_classroom).and_return(nil) }

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    context 'as a teacher' do
      let(:teacher) { create(:teacher) }
      let(:selected_unity) { create(:unity) }
      let(:classroom) { create(:classroom, unity: selected_unity, year: Date.current.year) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(user).to receive(:current_role_is_admin_or_employee?).and_return(false)
        allow(controller).to receive(:current_teacher).and_return(teacher)
        allow(controller).to receive(:current_unity).and_return(selected_unity)
        allow(controller).to receive(:current_school_year).and_return(Date.current.year)
        allow(controller).to receive(:current_user_classroom).and_return(classroom)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: classroom, year: Date.current.year)
      end

      it 'opens filtered by the profile classroom' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        target = create(:individualized_educational_plan, classroom: classroom, year: Date.current.year)
        create(:individualized_educational_plan, classroom: other_classroom, year: Date.current.year)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to contain_exactly(target)
      end

      it 'lists all teacher classrooms when the classroom filter is cleared' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        plan_in_profile = create(:individualized_educational_plan, classroom: classroom, year: Date.current.year)
        plan_in_other = create(:individualized_educational_plan, classroom: other_classroom, year: Date.current.year)

        get :index, params: { locale: 'pt-BR', filter: { by_classroom_id: '' } }

        expect(assigns(:individualized_educational_plans)).to contain_exactly(plan_in_profile, plan_in_other)
      end

      it 'renders empty when the teacher has no linked classrooms' do
        allow(TeacherClassroomAndDisciplineFetcher).to receive(:fetch!).and_return(nil)
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:individualized_educational_plans)).to be_empty
      end
    end
  end

  describe 'GET #fetch_students_by_classroom' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    let(:classroom) { create(:classroom) }

    it 'returns only students that have a plan in the classroom' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      create(:individualized_educational_plan)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end
  end

  describe 'GET #student_data' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    it 'returns the student identification data as json' do
      student = create(:student)
      allow(IndividualizedEducationalPlanPrefill).to receive(:student_data)
        .and_return(birth_date: '10/03/2015', diagnosis: 'TEA', guardians: 'Maria Silva')

      get :student_data, params: { locale: 'pt-BR', student_id: student.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq(
        'birth_date' => '10/03/2015', 'diagnosis' => 'TEA', 'guardians' => 'Maria Silva'
      )
    end
  end

  describe 'POST #create' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    let(:valid_params) do
      {
        student_id: create(:student).id,
        unity_id: create(:unity).id,
        classroom_id: create(:classroom).id,
        teacher_id: create(:teacher).id,
        year: Date.current.year,
        elaborated_at: Date.current,
        characterization: 'Perfil do estudante',
        iep_review_dates_attributes: { '0' => { review_date: Date.current + 30 } }
      }
    end

    it 'creates a draft plan and redirects to the index' do
      expect do
        post :create, params: { locale: 'pt-BR', individualized_educational_plan: valid_params }
      end.to change(IndividualizedEducationalPlan, :count).by(1)

      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    it 'persists the review dates' do
      post :create, params: { locale: 'pt-BR', individualized_educational_plan: valid_params }

      expect(IndividualizedEducationalPlan.last.iep_review_dates.map(&:review_date)).to eq([Date.current + 30])
    end

    it 'assigns the multi-select options' do
      option = create(:iep_option)

      post :create, params: {
        locale: 'pt-BR',
        individualized_educational_plan: valid_params.merge(communication_profile_option_ids: [option.id])
      }

      expect(IndividualizedEducationalPlan.last.communication_profile_option_ids).to eq([option.id])
    end

    it 'does not create an invalid plan (missing required fields)' do
      expect do
        post :create, params: {
          locale: 'pt-BR', individualized_educational_plan: valid_params.merge(student_id: nil)
        }
      end.not_to change(IndividualizedEducationalPlan, :count)
    end

    it 'persists section 4 (curricular planning) and section 5 (periodic evaluation)' do
      discipline = create(:discipline)
      accommodation = create(:iep_option, :instructional_accommodation)

      post :create, params: {
        locale: 'pt-BR',
        individualized_educational_plan: valid_params.merge(
          iep_curricular_plannings_attributes: { '0' => {
            discipline_id: discipline.id, long_term_goal: 'Meta anual',
            instructional_accommodation_option_ids: [accommodation.id]
          } },
          iep_periodic_evaluations_attributes: { '0' => {
            discipline_id: discipline.id, acquired_skills: 'Habilidades adquiridas'
          } }
        )
      }

      plan = IndividualizedEducationalPlan.last
      planning = plan.iep_curricular_plannings.first
      expect(planning.long_term_goal).to eq('Meta anual')
      expect(planning.instructional_accommodation_option_ids).to eq([accommodation.id])
      expect(plan.iep_periodic_evaluations.first.acquired_skills).to eq('Habilidades adquiridas')
    end
  end

  describe 'PATCH #update' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    it 'updates the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      patch :update, params: {
        locale: 'pt-BR', id: plan.id, individualized_educational_plan: { characterization: 'Atualizado' }
      }

      expect(plan.reload.characterization).to eq('Atualizado')
      expect(response).to redirect_to(individualized_educational_plans_path)
    end
  end
end
