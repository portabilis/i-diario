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
        expect(response.body).to include('last_step_absence_warning')
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
