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

      # Quando a configuracao geral permite recuperacao automatica, o checkbox
      # "Criar recuperacao desta avaliacao" deve vir marcado por padrao.
      context 'when allow_automatic_avaliation_recovery is enabled' do
        before do
          entity.using_connection do
            GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: true)
          end
        end

        it 'marks should_create_recovery as true by default' do
          entity.using_connection do
            get :new, params: { locale: 'pt-BR' }

            expect(assigns(:avaliation).should_create_recovery).to eq(true)
          end
        end
      end

      context 'when allow_automatic_avaliation_recovery is disabled' do
        before do
          entity.using_connection do
            GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: false)
          end
        end

        it 'leaves should_create_recovery as false' do
          entity.using_connection do
            get :new, params: { locale: 'pt-BR' }

            expect(assigns(:avaliation).should_create_recovery).to eq(false)
          end
        end
      end
    end
  end

  # Professores nao podem desabilitar a criacao automatica de recuperacao quando a
  # configuracao geral esta habilitada: o checkbox fica travado e o valor e forcado
  # no servidor. Usuarios administradores/funcionarios continuam podendo desmarcar.
  describe 'should_create_recovery lock for teachers' do
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'when allow_automatic_avaliation_recovery is enabled' do
      before do
        entity.using_connection do
          GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: true)
        end
      end

      it 'locks the checkbox when the current user is a teacher' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          get :new, params: { locale: 'pt-BR' }

          expect(assigns(:force_recovery_creation)).to eq(true)
        end
      end

      it 'does not lock the checkbox for non-teacher users' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(false)

          get :new, params: { locale: 'pt-BR' }

          expect(assigns(:force_recovery_creation)).to eq(false)
        end
      end

      it 'forces should_create_recovery to true on create even when submitted as false' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          post :create, params: {
            locale: 'pt-BR',
            avaliation: {
              classroom_id: classroom.id,
              discipline_id: discipline.id,
              test_date: Time.zone.today,
              description: 'Avaliacao trava recuperacao',
              grade_ids: classroom.grade_ids.join(','),
              should_create_recovery: '0'
            }
          }

          expect(assigns(:resource).should_create_recovery).to eq(true)
        end
      end

      it 'forces should_create_recovery to true on update even when submitted as false' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          # Avaliacao em memoria: isola o forcing do controller das validacoes do
          # model (dia letivo, data de postagem etc.), que nao sao o foco do teste.
          avaliation = Avaliation.new
          allow(controller).to receive(:resource).and_return(avaliation)

          patch :update, params: {
            locale: 'pt-BR',
            id: 1,
            avaliation: {
              grade_ids: '',
              should_create_recovery: '0'
            }
          }

          expect(assigns(:avaliation).should_create_recovery).to eq(true)
        end
      end

      it 'forces should_create_recovery to true on create_multiple_classrooms even when submitted as false' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          post :create_multiple_classrooms, params: {
            locale: 'pt-BR',
            avaliation_multiple_creator_form: {
              unity_id: unity.id,
              discipline_id: discipline.id,
              school_calendar_id: school_calendar.id,
              avaliations_attributes: {
                '0' => {
                  include: '1',
                  classroom_id: classroom.id,
                  test_date: Time.zone.today,
                  grade_ids: classroom.grade_ids.join(','),
                  should_create_recovery: '0'
                }
              }
            }
          }

          avaliations = assigns(:avaliation_multiple_creator_form).avaliations

          expect(avaliations).not_to be_empty
          expect(avaliations.map(&:should_create_recovery)).to all(eq(true))
        end
      end

      # Admins/funcionarios continuam podendo desmarcar: o valor enviado deve ser
      # respeitado no servidor, sem forcar a criacao da recuperacao.
      it 'keeps should_create_recovery as false on create for non-teacher users' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(false)

          post :create, params: {
            locale: 'pt-BR',
            avaliation: {
              classroom_id: classroom.id,
              discipline_id: discipline.id,
              test_date: Time.zone.today,
              description: 'Avaliacao admin sem recuperacao',
              grade_ids: classroom.grade_ids.join(','),
              should_create_recovery: '0'
            }
          }

          expect(assigns(:resource).should_create_recovery).to eq(false)
        end
      end
    end

    context 'when allow_automatic_avaliation_recovery is disabled' do
      before do
        entity.using_connection do
          GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: false)
        end
      end

      it 'does not lock the checkbox even for teachers' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          get :new, params: { locale: 'pt-BR' }

          expect(assigns(:force_recovery_creation)).to eq(false)
        end
      end

      # Com a config desligada, nem mesmo o professor e forcado: o valor enviado
      # deve ser respeitado.
      it 'keeps should_create_recovery as false on create when teacher submits false' do
        entity.using_connection do
          allow(user).to receive(:teacher?).and_return(true)

          post :create, params: {
            locale: 'pt-BR',
            avaliation: {
              classroom_id: classroom.id,
              discipline_id: discipline.id,
              test_date: Time.zone.today,
              description: 'Avaliacao professor config desligada',
              grade_ids: classroom.grade_ids.join(','),
              should_create_recovery: '0'
            }
          }

          expect(assigns(:resource).should_create_recovery).to eq(false)
        end
      end
    end
  end

  # A lista de disciplinas do re-render precisa vir do mesmo metodo da tela inicial: admin e
  # funcionario nao tem vinculo de professor, entao um filtro por turma devolve lista vazia e o
  # campo Disciplina fica sem opcoes.
  describe '#create_multiple_classrooms' do
    # Os dados precisam ser criados dentro da mesma conexao (entity) usada pela action.
    before do
      entity.using_connection do
        @mc_unity = create(:unity)
        @mc_teacher = create(:teacher)
        @mc_discipline = create(:discipline)
        mc_school_calendar = create(:school_calendar, :with_one_step, unity: @mc_unity)
        @mc_classroom = create(:classroom, unity: @mc_unity, school_calendar: mc_school_calendar)
        create(:teacher_discipline_classroom,
               teacher: @mc_teacher,
               discipline: @mc_discipline,
               classroom: @mc_classroom)

        allow(controller).to receive(:current_teacher).and_return(@mc_teacher)
        allow(controller).to receive(:current_teacher_id).and_return(@mc_teacher.id)
        allow(controller).to receive(:current_unity).and_return(@mc_unity)
        allow(controller).to receive(:current_school_year).and_return(@mc_classroom.year)
        allow(controller).to receive(:current_school_calendar).and_return(mc_school_calendar)
        allow(controller).to receive(:current_user_classroom).and_return(@mc_classroom)
        allow(controller).to receive(:current_user_discipline).and_return(@mc_discipline)
      end
    end

    context 'when the form is invalid and the user is an administrator' do
      it 'assigns the disciplines of the current unity and teacher' do
        entity.using_connection do
          post :create_multiple_classrooms, params: {
            locale: 'pt-BR',
            avaliation_multiple_creator_form: {
              unity_id: @mc_unity.id,
              discipline_id: @mc_discipline.id,
              test_setting_id: ''
            }
          }

          expect(assigns(:avaliation_multiple_creator_form)).not_to be_valid
          expect(assigns(:disciplines)).to contain_exactly(@mc_discipline)
        end
      end
    end
  end

  describe '#multiple_classrooms' do
    # Os dados precisam ser criados dentro da mesma conexao (entity) usada pela
    # action, caso contrario load_avaliations! nao enxerga os registros.
    before do
      entity.using_connection do
        mc_unity = create(:unity)
        mc_teacher = create(:teacher)
        mc_discipline = create(:discipline)
        mc_school_calendar = create(:school_calendar, :with_one_step, unity: mc_unity)
        @mc_classroom = create(:classroom, unity: mc_unity)
        create(:teacher_discipline_classroom,
               teacher: mc_teacher,
               discipline: mc_discipline,
               classroom: @mc_classroom)

        TestSetting.find_or_create_by!(year: @mc_classroom.year) do |ts|
          ts.exam_setting_type = ExamSettingTypes::GENERAL
          ts.maximum_score = 10
          ts.number_of_decimal_places = 2
          ts.average_calculation_type = AverageCalculationTypes::ARITHMETIC
        end

        allow(controller).to receive(:current_teacher).and_return(mc_teacher)
        allow(controller).to receive(:current_teacher_id).and_return(mc_teacher.id)
        allow(controller).to receive(:current_unity).and_return(mc_unity)
        allow(controller).to receive(:current_school_year).and_return(mc_school_calendar.year)
        allow(controller).to receive(:current_school_calendar).and_return(mc_school_calendar)
        allow(controller).to receive(:current_user_classroom).and_return(@mc_classroom)
        allow(controller).to receive(:current_user_discipline).and_return(mc_discipline)
      end
    end

    context 'when allow_automatic_avaliation_recovery is enabled' do
      before do
        entity.using_connection do
          GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: true)
        end
      end

      it 'marks should_create_recovery as true for every loaded avaliation' do
        entity.using_connection do
          get :multiple_classrooms, params: { locale: 'pt-BR' }

          avaliations = assigns(:avaliation_multiple_creator_form).avaliations

          expect(avaliations).not_to be_empty
          expect(avaliations.map(&:should_create_recovery)).to all(eq(true))
        end
      end
    end

    context 'when allow_automatic_avaliation_recovery is disabled' do
      before do
        entity.using_connection do
          GeneralConfiguration.current.update!(allow_automatic_avaliation_recovery: false)
        end
      end

      it 'leaves should_create_recovery as false for every loaded avaliation' do
        entity.using_connection do
          get :multiple_classrooms, params: { locale: 'pt-BR' }

          avaliations = assigns(:avaliation_multiple_creator_form).avaliations

          expect(avaliations).not_to be_empty
          expect(avaliations.map(&:should_create_recovery)).to all(eq(false))
        end
      end
    end
  end
end
