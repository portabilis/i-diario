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

        get :index, params: { locale: 'pt-BR', page: 1 }
        first_page_ids = assigns(:individualized_educational_plans).map(&:id)

        get :index, params: { locale: 'pt-BR', page: 2 }
        second_page = assigns(:individualized_educational_plans)

        expect(second_page.to_a.size).to eq(1)
        expect(first_page_ids).not_to include(second_page.first.id)
      end
    end

    context 'without a classroom selected in the profile' do
      before { allow(controller).to receive(:current_user_classroom).and_return(nil) }

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    # O index exige contexto de professor para todos os perfis (before_action
    # require_current_teacher). Fixa a decisão: sem current_teacher, redireciona.
    context 'without a current teacher' do
      before do
        allow(controller).to receive(:require_current_teacher).and_call_original
        allow(controller).to receive(:current_teacher).and_return(nil)
        allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
      end

      it 'redirects to the root path' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to redirect_to(root_path)
      end
    end

    context 'when not authorized (Pundit)' do
      before do
        allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
        allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)
      end

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

  describe 'DELETE #destroy' do
    before { allow(controller).to receive(:current_user_classroom).and_return(create(:classroom)) }

    it 'destroys the plan and redirects to the index' do
      plan = create(:individualized_educational_plan)

      expect {
        delete :destroy, params: { locale: 'pt-BR', id: plan.id }
      }.to change(IndividualizedEducationalPlan, :count).by(-1)

      expect(response).to redirect_to(individualized_educational_plans_path)
    end
  end

  describe 'GET #fetch_students_by_classroom' do
    let(:classroom) { create(:classroom) }

    it 'returns only students that have a plan in the classroom' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      create(:individualized_educational_plan) # plano em outra turma

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end

    it 'excludes a student without a plan in the classroom' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      create(:student) # aluno sem PEI — não deve ser listado

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end

    it 'sorts the students by name' do
      zilda = create(:student, name: 'Zilda')
      ana = create(:student, name: 'Ana')
      create(:individualized_educational_plan, classroom: classroom, student: zilda)
      create(:individualized_educational_plan, classroom: classroom, student: ana)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(JSON.parse(response.body).map { |s| s['name'] }).to eq(%w[Ana Zilda])
    end

    it 'returns an empty list when no classroom is given' do
      create(:individualized_educational_plan)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: '', format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end

    it 'redirects to the root path when not authorized (Pundit)' do
      allow(controller).to receive(:authorize).and_raise(Pundit::NotAuthorizedError)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to redirect_to(root_path)
    end
  end
end
