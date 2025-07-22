# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplementaryExamsController, type: :controller do
  describe '#index' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:user) { create(:user, :with_user_role_administrator) }
    let(:teacher) { create(:teacher) }
    let(:unity) { create(:unity) }
    let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity) }
    let(:classroom) { create(:classroom, unity: unity, school_calendar: school_calendar) }
    let(:discipline) { create(:discipline) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom,
             teacher: teacher,
             discipline: discipline,
             classroom: classroom)
    end

    before do
      entity.using_connection do
        sign_in(user)
        
        # Mock all required methods
        allow(controller).to receive(:authorize).and_return(true)
        allow(controller).to receive(:require_current_teacher).and_return(true)
        allow(controller).to receive(:require_allow_to_modify_prev_years).and_return(true)
        allow(controller).to receive(:current_teacher).and_return(teacher)
        allow(controller).to receive(:current_teacher_id).and_return(teacher.id)
        allow(controller).to receive(:current_unity).and_return(unity)
        allow(controller).to receive(:current_school_year).and_return(Date.current.year)
        allow(controller).to receive(:current_user_classroom).and_return(classroom.id)
        allow(controller).to receive(:current_user_discipline).and_return(discipline.id)
      end
    end

    it 'does not raise error when filtering by step_id' do
      entity.using_connection do
        expect do
          get :index, params: { locale: 'pt-BR', filter: { by_step_id: school_calendar.steps.first.id } }
        end.not_to raise_error
      end
    end

    it 'calls set_options_by_user which sets @classrooms' do
      entity.using_connection do
        get :index, params: { locale: 'pt-BR' }
        expect(assigns(:classrooms)).not_to be_nil
      end
    end
  end
end
