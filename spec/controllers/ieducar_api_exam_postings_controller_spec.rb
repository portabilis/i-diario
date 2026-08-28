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
