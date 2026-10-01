require 'spec_helper'

RSpec.describe IeducarApiExamPostingsController, :type => :controller do
  describe 'POST #create' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:unity) { create(:unity) }
    let(:teacher) { create(:teacher) }
    let(:classroom) { create(:classroom, unity: unity) }
    let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity) }
    let(:step) { school_calendar.steps.first }
    let(:user) { create(:user_with_user_role, teacher_id: teacher.id, current_classroom_id: classroom.id) }
    let!(:ieducar_api_configuration) { create(:ieducar_api_configuration) }

    around do |example|
      entity.using_connection { example.run }
    end

    before do
      sign_in(user)
      allow(controller).to receive(:current_entity).and_return(entity)
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:current_teacher).and_return(teacher)
      allow(controller).to receive(:require_current_classroom).and_return(true)
      allow(controller).to receive(:require_current_teacher).and_return(true)
      allow(controller).to receive(:require_current_teacher_discipline_classrooms).and_return(true)
      allow(controller).to receive(:require_current_posting_step).and_return(true)
      allow(controller).to receive(:authorize).and_return(true)
    end

    # Perder o automatic: false faria um envio automático (de uma turma só) virar base incremental
    # do envio manual, que passaria a pular as demais turmas do professor.
    it 'launches a manual posting for the current user and teacher' do
      expect(IeducarExamPostingLauncher).to receive(:call) do |arguments|
        expect(arguments[:attributes]).to include(
          'school_calendar_step_id' => step.id.to_s,
          'post_type' => ApiPostingTypes::ABSENCE,
          'author' => user,
          'teacher' => teacher,
          'ieducar_api_configuration' => ieducar_api_configuration,
          'automatic' => false
        )
        expect(arguments[:entity_id]).to eq(entity.id)
        expect(arguments[:force_posting]).to eq('true')
      end

      post :create, params: {
        locale: 'pt-BR',
        school_calendar_step_id: step.id,
        post_type: ApiPostingTypes::ABSENCE,
        force_posting: 'true'
      }
    end
  end

  describe 'GET #index' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:unity) { create(:unity) }
    let(:teacher) { create(:teacher) }
    let!(:school_calendar) { create(:school_calendar, :with_trimester_steps, unity: unity) }
    let(:classroom) { create(:classroom, unity: unity, year: school_calendar.year) }
    let(:user) { create(:user_with_user_role, teacher_id: teacher.id, current_classroom_id: classroom.id) }

    around do |example|
      entity.using_connection { example.run }
    end

    before do
      sign_in(user)
      allow(controller).to receive(:current_entity).and_return(entity)
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:current_teacher).and_return(teacher)
      allow(controller).to receive(:require_current_classroom).and_return(true)
      allow(controller).to receive(:require_current_teacher).and_return(true)
      allow(controller).to receive(:require_current_teacher_discipline_classrooms).and_return(true)
      allow(controller).to receive(:require_current_posting_step).and_return(true)
    end

    # O usuário é admin: vê todas as etapas, sem o filtro da janela de envio.
    it 'flags only the absence posting of the last step of the year' do
      get :index, params: { locale: 'pt-BR' }

      first_step = school_calendar.steps.ordered.first
      last_step = school_calendar.steps.ordered.last

      expect(controller.send(:last_step_absence_warning?, last_step, ApiPostingTypes::ABSENCE)).to eq(true)
      expect(controller.send(:last_step_absence_warning?, first_step, ApiPostingTypes::ABSENCE)).to eq(false)
      expect(controller.send(:last_step_absence_warning?, last_step, ApiPostingTypes::NUMERICAL_EXAM)).to eq(false)
    end

    context 'when rendering the views' do
      render_views

      # O layout referencia os pacotes do webpack, que não são compilados no ambiente de teste.
      before do
        allow_any_instance_of(ActionView::Base).to receive(:javascript_pack_tag).and_return('')
        allow_any_instance_of(ActionView::Base).to receive(:stylesheet_pack_tag).and_return('')
      end

      # Duas marcações: os botões "Enviar" e "Repetir envio" da linha de faltas da última etapa.
      it 'marks the absence links of the last step and renders the warning modal' do
        get :index, params: { locale: 'pt-BR' }

        expect(response.body.scan('data-last-step-absence-warning="true"').size).to eq(2)
        expect(response.body).to include('id="last-step-absence-warning-modal"')
      end

      context 'when the classroom has no school calendar' do
        let(:classroom) { create(:classroom, unity: create(:unity), year: school_calendar.year) }

        it 'marks no link and renders no modal' do
          get :index, params: { locale: 'pt-BR' }

          expect(response.body).not_to include('data-last-step-absence-warning')
          expect(response.body).not_to include('id="last-step-absence-warning-modal"')
        end
      end
    end
  end

  describe 'posting window access' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:today) { Time.zone.today }
    let(:open_window) { { start_date_for_posting: today - 5, end_date_for_posting: today + 5 } }
    let(:closed_window) { { start_date_for_posting: today + 10, end_date_for_posting: today + 20 } }
    let(:posting_period_alert) { I18n.t('errors.ieducar_api_exam_postings.require_current_posting_step') }
    let(:unity) { create(:unity) }
    let(:teacher) { create(:teacher) }
    let(:school_calendar) { create(:school_calendar, unity: unity, year: today.year) }
    let(:classroom) { create(:classroom, unity: unity, year: today.year) }
    let(:unity_window) { closed_window }
    let!(:unity_step) do
      create(:school_calendar_step, school_calendar: school_calendar, step_number: 1,
                                    start_at: today.beginning_of_year, end_at: today.end_of_year, **unity_window)
    end
    # Admin passa por qualquer trava de permissão; o gate só é exercitado por professor sem a
    # permissão de envio sem restrição de data.
    let(:user) do
      create(:user, :with_user_role_teacher, admin: false, teacher_id: teacher.id, current_classroom_id: classroom.id,
                                             current_unity_id: unity.id, current_school_year: today.year)
    end

    around do |example|
      entity.using_connection { example.run }
    end

    before do
      sign_in(user)
      allow(controller).to receive(:current_entity).and_return(entity)
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:current_teacher).and_return(teacher)
      allow(controller).to receive(:require_current_classroom).and_return(true)
      allow(controller).to receive(:require_current_teacher).and_return(true)
      allow(controller).to receive(:require_current_teacher_discipline_classrooms).and_return(true)
    end

    # As etapas do calendário da turma substituem integralmente as da unidade, janela de lançamento inclusive.
    context 'when the classroom has its own school calendar' do
      let(:classroom_window) { open_window }
      let(:school_calendar_classroom) do
        create(:school_calendar_classroom, classroom: classroom, school_calendar: school_calendar)
      end
      let!(:classroom_step) do
        create(:school_calendar_classroom_step, school_calendar_classroom: school_calendar_classroom, step_number: 1,
                                                start_at: today.beginning_of_year, end_at: today.end_of_year,
                                                **classroom_window)
      end

      context 'when only the classroom posting window is open today' do
        it 'grants access and lists the classroom step' do
          get :index, params: { locale: 'pt-BR' }

          expect(response).to have_http_status(:ok)
          expect(assigns(:steps)).to contain_exactly(classroom_step)
        end

        it 'accepts a posting for the classroom step' do
          allow(controller).to receive(:authorize).and_return(true)
          expect(IeducarExamPostingLauncher).to receive(:call)

          post :create, params: {
            locale: 'pt-BR',
            school_calendar_classroom_step_id: classroom_step.id,
            post_type: ApiPostingTypes::NUMERICAL_EXAM
          }

          expect(response).to redirect_to(ieducar_api_exam_postings_path)
        end
      end

      context 'when only the unity posting window is open today' do
        let(:unity_window) { open_window }
        let(:classroom_window) { closed_window }

        it 'redirects with the posting period alert' do
          get :index, params: { locale: 'pt-BR' }

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(posting_period_alert)
        end
      end

      context 'when the user can post without date restrictions' do
        let(:classroom_window) { closed_window }

        before do
          allow(user).to receive(:can_change?).and_call_original
          allow(user).to receive(:can_change?)
            .with(Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS).and_return(true)
        end

        it 'grants access and lists the classroom step outside its posting window' do
          get :index, params: { locale: 'pt-BR' }

          expect(response).to have_http_status(:ok)
          expect(assigns(:steps)).to contain_exactly(classroom_step)
        end
      end
    end

    context 'when the classroom follows the unity school calendar' do
      context 'when the unity posting window is open today' do
        let(:unity_window) { open_window }

        it 'grants access and lists the unity step' do
          get :index, params: { locale: 'pt-BR' }

          expect(response).to have_http_status(:ok)
          expect(assigns(:steps)).to contain_exactly(unity_step)
        end
      end

      context 'when the unity posting window is closed today' do
        it 'redirects with the posting period alert' do
          get :index, params: { locale: 'pt-BR' }

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to eq(posting_period_alert)
        end
      end
    end

    # Sem calendário na unidade corrente do usuário para o ano não há janela a conferir, e a tela segue liberada.
    context 'when there is no school calendar for the current unity and year' do
      let(:other_unity) { create(:unity) }
      let(:classroom) { create(:classroom, unity: other_unity, year: today.year) }
      let(:user) do
        create(:user, :with_user_role_teacher, admin: false, teacher_id: teacher.id, current_classroom_id: classroom.id,
                                               current_unity_id: other_unity.id, current_school_year: today.year)
      end

      it 'grants access with no steps' do
        get :index, params: { locale: 'pt-BR' }

        expect(response).to have_http_status(:ok)
        expect(assigns(:steps).to_a).to eq([])
      end
    end
  end

  context "pt-BR routes" do
    it "routes to index" do
      expect(get: "envio-de-avaliacoes").to route_to(
        action: "index",
        controller: "ieducar_api_exam_postings",
        locale: "pt-BR"
      )
    end

    it "routes to create" do
      expect(post: "envio-de-avaliacoes").to route_to(
        action: "create",
        controller: "ieducar_api_exam_postings",
        locale: "pt-BR"
      )
    end
  end
end
