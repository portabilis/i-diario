# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AvaliationsController, type: :controller do
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

      allow(controller).to receive(:authorize).and_return(true)
      allow(controller).to receive(:require_current_classroom).and_return(true)
      allow(controller).to receive(:require_current_teacher).and_return(true)
      allow(controller).to receive(:require_allow_to_modify_prev_years).and_return(true)
      allow(controller).to receive(:current_teacher).and_return(teacher)
      allow(controller).to receive(:current_teacher_id).and_return(teacher.id)
      allow(controller).to receive(:current_unity).and_return(unity)
      allow(controller).to receive(:current_school_year).and_return(classroom.year)
      allow(controller).to receive(:current_school_calendar).and_return(school_calendar)
      allow(controller).to receive(:current_user_classroom).and_return(classroom)
      allow(controller).to receive(:current_user_discipline).and_return(discipline)
      allow(controller).to receive(:score_types_redirect).and_return(nil)
      allow(controller).to receive(:not_allow_numerical_exam).and_return(nil)
    end
  end

  # Quando nao existe TestSetting para o ano da turma, o professor deve ser
  # redirecionado com mensagem de erro ao tentar criar uma avaliacao.
  # Reproduz Honeybadger fault #128563728
  describe '#new' do
    context 'when there are no test settings for the classroom year' do
      before do
        entity.using_connection do
          TestSetting.where(year: classroom.year).destroy_all
        end
      end

      it 'redirects to avaliations index with error message' do
        entity.using_connection do
          get :new, params: { locale: 'pt-BR' }

          expect(response).to redirect_to(avaliations_path)
          expect(flash[:error]).to eq('É necessário configurar uma avaliação numérica')
        end
      end
    end

    context 'when test settings exist for the classroom year' do
      before do
        entity.using_connection do
          TestSetting.find_or_create_by!(year: classroom.year) do |ts|
            ts.exam_setting_type = ExamSettingTypes::GENERAL
            ts.maximum_score = 10
            ts.number_of_decimal_places = 2
            ts.average_calculation_type = AverageCalculationTypes::ARITHMETIC
          end
        end
      end

      it 'does not redirect' do
        entity.using_connection do
          get :new, params: { locale: 'pt-BR' }

          expect(response).not_to redirect_to(avaliations_path)
        end
      end
    end
  end
end
