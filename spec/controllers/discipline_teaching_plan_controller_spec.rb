require 'spec_helper'

RSpec.describe DisciplineTeachingPlansController, type: :controller do
  let(:user) { create(:user_with_user_role) }
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

  describe 'GET discipline_teaching_plans#index' do
    before(:each) do
      allow(controller).to receive(:current_user_is_employee_or_administrator?).and_return(false)
      allow(controller).to receive(:current_teacher).and_return(current_teacher)
      allow(controller).to receive(:current_user_unity).and_return(unity)
      allow(controller).to receive(:current_user_school_year).and_return(classroom.year)
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_user_discipline).and_return(discipline)
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
      context 'when the autor is the current teacher' do
        before do
          get :index, locale: 'pt-BR', fitler: { by_author: PlansAuthors::MY_PLANS }
        end

        it 'lists the current teacher plans' do
          expect(assigns(:discipline_teaching_plans)).to eq([current_teacher_discipline_teaching_plan])
        end
      end

      context 'when the autor is other teacher' do
        before do
          get :index, locale: 'pt-BR', fitler: { by_author: PlansAuthors::OTHERS }
        end

        it 'lists the other teachers plans' do
          expect(assigns(:discipline_teaching_plans)).to eq([other_teacher_discipline_teaching_plan])
        end
      end
    end
  end
end
