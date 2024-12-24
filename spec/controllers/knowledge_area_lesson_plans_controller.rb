require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlansController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  let(:unity) { create(:unity) }
  let(:current_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) {
    create(
      :school_calendar,
      :with_trimester_steps,
      unity: unity
    )
  }

  let(:classroom) {
    create(
      :classroom,
      :score_type_numeric,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      discipline: discipline,
      school_calendar: school_calendar,
      year: school_calendar.year,
      unity: unity
    )
  }

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

  let!(:knowledge_area_lesson_plan) {
    create(
      :knowledge_area_lesson_plan,
      :with_teacher_discipline_classroom,
      teacher: current_teacher,
      classroom: classroom
    )
  }

  let(:params) {
    {
      locale: 'pt-BR',
      knowledge_area_lesson_plan: {
        lesson_plan_id: knowledge_area_lesson_plan.lesson_plan.id
      }
    }
  }

  before(:each) do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    request.env['REQUEST_PATH'] = '/planos-de-aula-por-areas-de-conhecimento'
  end

  describe 'GET knowledge_area_lesson_plans#index' do
    context 'without filter' do
      before do
        get :index, params: { locale: 'pt-BR' }
      end

      it 'lists all records' do
        expect(assigns(:knowledge_area_lesson_plans)).to include(knowledge_area_lesson_plan)
      end
    end

    context 'with experience fields filter' do
      let!(:another_knowledge_area_lesson_plan) {
        create(
          :knowledge_area_lesson_plan,
          :with_teacher_discipline_classroom,
          teacher: current_teacher,
          classroom: classroom,
          experience_fields: 'test'
        )
      }

      context 'when the experience field matches a record' do
        before do
          get :index, params: { locale: 'pt-BR', filter: { by_experience_fields: another_knowledge_area_lesson_plan.experience_fields } }
        end

        it 'lists the records that match' do
          expect(assigns(:knowledge_area_lesson_plans).size).to eq(1)
          expect(assigns(:knowledge_area_lesson_plans)).to eq([another_knowledge_area_lesson_plan])
        end
      end

      context 'when the experience field does not match a record' do
        before do
          get :index, params: { locale: 'pt-BR', filter: { by_experience_fields: 'does not exist' } }
        end

        it 'does not list any record' do
          expect(assigns(:knowledge_area_lesson_plans).size).to eq(0)
        end
      end

      context 'without experience field' do
        before do
          get :index, params: { locale: 'pt-BR', filter: { by_experience_fields: nil } }
        end

        it 'lists all records' do
          expect(assigns(:knowledge_area_lesson_plans))
            .to include(knowledge_area_lesson_plan, another_knowledge_area_lesson_plan)
        end
      end
    end
  end

end
