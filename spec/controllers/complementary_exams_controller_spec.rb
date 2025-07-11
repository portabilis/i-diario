require 'rails_helper'

RSpec.describe ComplementaryExamsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :teacher, current_entity: entity) }
  let(:unity) { create(:unity) }
  let(:classroom) { create(:classroom, unity: unity) }
  let(:discipline) { create(:discipline) }
  let(:teacher) { create(:teacher) }
  let(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, 
           teacher: teacher,
           discipline: discipline,
           classroom: classroom)
  end

  before do
    sign_in(user)
    user.current_role = user.roles.first
    user.save!
    allow(controller).to receive(:current_teacher).and_return(teacher)
    allow(controller).to receive(:current_unity).and_return(unity)
    allow(controller).to receive(:current_school_year).and_return(Date.current.year)
    teacher_discipline_classroom
  end

  describe 'GET #index' do
    context 'when filtering by step_id' do
      let(:step) { double(id: 1, step_number: 1) }
      let(:steps_fetcher) { double(step_by_id: step) }

      before do
        allow(StepsFetcher).to receive(:new).and_return(steps_fetcher)
      end

      it 'filters complementary exams by step_id successfully' do
        get :index, params: { filter: { by_step_id: 1 } }
        
        expect(response).to be_successful
      end

      it 'uses @classrooms instead of @classroom' do
        expect {
          get :index, params: { filter: { by_step_id: 1 } }
        }.not_to raise_error
      end
    end

    context 'without filters' do
      it 'returns complementary exams successfully' do
        get :index
        
        expect(response).to be_successful
      end
    end
  end
end