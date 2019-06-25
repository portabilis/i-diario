require 'spec_helper'

RSpec.describe DisciplineTeachingPlansController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end
  let(:user) { create(:user_with_user_role, admin: false) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }
  let(:current_teacher_teaching_plan) {
    create(
      :teaching_plan,
      teacher: current_teacher,
      unity: unity,
      year: classroom.year,
      grade: classroom.grade
    )
  }
  let(:other_teacher_teaching_plan) {
    create(
      :teaching_plan,
      teacher: other_teacher,
      unity: unity,
      year: classroom.year,
      grade: classroom.grade
    )
  }
  let(:current_teacher_discipline_teaching_plan) {
    create(
      :discipline_teaching_plan,
      teaching_plan: current_teacher_teaching_plan,
      discipline: discipline
    )
  }
  let(:other_teacher_discipline_teaching_plan) {
    create(
      :discipline_teaching_plan,
      teaching_plan: other_teacher_teaching_plan,
      discipline: discipline
    )
  }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      teacher: current_teacher,
      discipline: discipline,
      classroom: classroom
    )
  }
  let(:params) {
    {
      locale: 'pt-BR',
      discipline_teaching_plan: {
        discipline_id: discipline.id,
        teaching_plan_attributes: {
          id: '',
          year: classroom.year,
          unity_id: unity.id,
          grade_id: classroom.grade.id,
          school_term_type: SchoolTermTypes::BIMESTER,
          school_term: Bimesters::FIRST_BIMESTER,
          teacher_id: current_teacher.id,
          contents_attributes: {
            '1': {
              description: current_teacher_teaching_plan.contents.first.description,
              id: '',
              _destroy: false
            }
          }
        }
      }
    }
  }

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user_is_employee_or_administrator?).and_return(false)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_user_unity).and_return(unity)
    allow(controller).to receive(:current_user_school_year).and_return(classroom.year)
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
    allow(controller).to receive(:current_user_discipline).and_return(discipline)
  end

  describe 'GET discipline_teaching_plans#index' do
    before(:each) do
      allow(controller).to receive(:fetch_grades).and_return([])
      allow(controller).to receive(:fetch_disciplines).and_return([])
    end

    context 'without author filter' do
      before do
        get :index, locale: 'pt-BR'
      end

      it 'lists all plans' do
        expect(assigns(:discipline_teaching_plans)).to include(
          current_teacher_discipline_teaching_plan,
          other_teacher_discipline_teaching_plan
        )
      end
    end

    context 'with author filter' do
      context 'when the author is the current teacher' do
        before do
          get :index, locale: 'pt-BR', fitler: { by_author: PlansAuthors::MY_PLANS }
        end

        it 'lists the current teacher plans' do
          expect(assigns(:discipline_teaching_plans)).to eq([current_teacher_discipline_teaching_plan])
        end
      end

      context 'when the author is other teacher' do
        before do
          get :index, locale: 'pt-BR', fitler: { by_author: PlansAuthors::OTHERS }
        end

        it 'lists the other teachers plans' do
          expect(assigns(:discipline_teaching_plans)).to eq([other_teacher_discipline_teaching_plan])
        end
      end
    end
  end

  describe 'POST discipline_teaching_plans#create' do
    context 'without success' do
      it 'fails to create and renders the new template' do
        allow(controller).to receive(:fetch_collections).and_return([])
        params[:discipline_teaching_plan][:discipline_id] = nil
        post :create, params.merge(params)
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to discipline_teaching_plans#index' do
        post :create, params.merge(params)
        expect(response).to redirect_to(discipline_teaching_plans_path)
      end
    end
  end
end
