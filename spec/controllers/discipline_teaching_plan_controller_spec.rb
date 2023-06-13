require 'spec_helper'

RSpec.describe DisciplineTeachingPlansController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end
  before(:each) do
    TeachingPlan.any_instance.stub(:yearly?).and_return(false)
  end
  let(:user) do
    create(
      :user_with_user_role,
      admin: false,
      teacher_id: current_teacher.id,
      current_unity_id: classroom.unity_id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end
  let(:school_calendar) do
    create(
      :school_calendar,
      year: classroom.year,
      unity: classroom.unity
    )
  end
  let(:user_role) { user.user_roles.first }
  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:classroom) { create(:classroom, :score_type_numeric) }
  let(:discipline) { create(:discipline) }
  let(:school_term_type) { create(:school_term_type, description: 'Anual') }
  let(:school_term_type_step) { create(:school_term_type_step, school_term_type: school_term_type) }
  let(:current_teacher_teaching_plan) {
    create(
      :teaching_plan,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      unity: classroom.unity,
      year: classroom.year,
      grade: classroom.classrooms_grades.first.grade,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step
    )
  }
  let(:other_teacher_teaching_plan) {
    create(
      :teaching_plan,
      :with_teacher_discipline_classroom,
      teacher: other_teacher,
      unity: classroom.unity,
      year: classroom.year,
      grade: classroom.classrooms_grades.first.grade,
      school_term_type: school_term_type,
      school_term_type_step: school_term_type_step
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
  let(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      teacher: current_teacher,
      discipline: discipline,
      classroom: classroom,
      grade: classroom.classrooms_grades.first.grade
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
          unity_id: classroom.unity_id,
          grade_id: classroom.classrooms_grades.first.grade_id,
          school_term_type_id: school_term_type.id,
          school_term_type_step_id: school_term_type_step.id,
          teacher_id: current_teacher.id,
          content_descriptions: [
            Faker::Lorem.sentence
          ]
        }
      }
    }
  }

  before do
    school_term_type
    school_term_type_step
    school_calendar
    teacher_discipline_classroom
    user_role.unity = classroom.unity
    user_role.save!

    user.current_user_role = user_role
    user.save!

    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user_is_employee_or_administrator?).and_return(false)
    allow(controller).to receive(:can_change_school_year?).and_return(true)
    request.env['REQUEST_PATH'] = '/discipline_teaching_plans'
  end

  describe 'POST discipline_teaching_plans#index' do
    before(:each) do
      allow(controller).to receive(:fetch_grades).and_return([])
      allow(controller).to receive(:fetch_disciplines).and_return([])
    end

    context 'without author filter' do
      before do
        post :index, params: { locale: 'pt-BR', filter: { by_author: '' } }
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
          get :index, params: { locale: 'pt-BR', filter: { by_author: PlansAuthors::MY_PLANS } }
        end

        it 'lists the current teacher plans' do
          expect(assigns(:discipline_teaching_plans)).to eq([current_teacher_discipline_teaching_plan])
        end
      end

      context 'when the author is other teacher' do
        before do
          get :index, params: { locale: 'pt-BR', filter: { by_author: PlansAuthors::OTHERS } }
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
        allow(controller).to receive(:yearly_term_type_id).and_return(1)
        params[:discipline_teaching_plan][:discipline_id] = nil
        expect { post :create, params: params.merge(params) }.to_not change(DisciplineTeachingPlan, :count)
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to discipline_teaching_plans#index' do
        expect { post :create, params: params.merge(params)  }.to change(DisciplineTeachingPlan, :count).by(1)
        expect(response).to redirect_to(discipline_teaching_plans_path)
      end
    end
  end
end
