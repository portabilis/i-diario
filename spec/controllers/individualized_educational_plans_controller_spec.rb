require 'rails_helper'

RSpec.describe IndividualizedEducationalPlansController, type: :controller do
  render_views

  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  around(:each) do |example|
    entity.using_connection { example.run }
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
  end

  describe 'GET #index' do
    context 'as an admin/employee' do
      let(:classroom) { create(:classroom) }

      before { allow(controller).to receive(:current_user_classroom).and_return(classroom) }

      it 'renders the selected classroom plans' do
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end

      it 'filters by student' do
        target = create(:individualized_educational_plan, classroom: classroom)
        create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR', filter: { by_student_id: target.student_id } }

        expect(controller.view_assigns['individualized_educational_plans']).to contain_exactly(target)
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
        expect(controller.view_assigns['individualized_educational_plans']).to contain_exactly(target)
      end

      it 'lists all teacher classrooms when the classroom filter is cleared' do
        other_classroom = create(:classroom, unity: selected_unity, year: Date.current.year)
        create(:teacher_discipline_classroom, teacher: teacher, classroom: other_classroom, year: Date.current.year)
        plan_in_profile = create(:individualized_educational_plan, classroom: classroom, year: Date.current.year)
        plan_in_other = create(:individualized_educational_plan, classroom: other_classroom, year: Date.current.year)

        get :index, params: { locale: 'pt-BR', filter: { by_classroom_id: '' } }

        expect(controller.view_assigns['individualized_educational_plans']).to contain_exactly(plan_in_profile, plan_in_other)
      end
    end
  end

  describe 'GET #fetch_students_by_classroom' do
    let(:classroom) { create(:classroom) }

    it 'returns only students that have a plan in the classroom' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      create(:individualized_educational_plan)

      get :fetch_students_by_classroom, params: { locale: 'pt-BR', classroom_id: classroom.id, format: :json }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to contain_exactly('id' => plan.student_id, 'name' => plan.student.name)
    end
  end
end
