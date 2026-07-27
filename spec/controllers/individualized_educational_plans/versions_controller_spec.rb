require 'rails_helper'

RSpec.describe IndividualizedEducationalPlans::VersionsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  around(:each) do |example|
    entity.using_connection { example.run }
  end

  let(:classroom) { create(:classroom) }

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:require_current_teacher).and_return(true)
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
  end

  describe 'GET #index' do
    it 'lists the plan versions, most recent first' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      older = create(:iep_version, iep: plan, published_at: 2.days.ago, active: false)
      newer = create(:iep_version, iep: plan, published_at: 1.day.ago, active: true)
      create(:iep_version) # versão de outro PEI, não deve aparecer

      get :index, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:versions)).to eq([newer, older])
    end

    it 'renders an empty history when the plan has no versions yet' do
      plan = create(:individualized_educational_plan, classroom: classroom)

      get :index, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:versions)).to eq([])
    end

    it 'does not list versions of a plan from a classroom the user is not linked to' do
      plan = create(:individualized_educational_plan, classroom: create(:classroom))

      get :index, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id }

      expect(response).to redirect_to(individualized_educational_plans_path)
    end

    context 'with real authorization' do
      before { allow(controller).to receive(:authorize).and_call_original }

      it 'denies access when the user cannot view the feature' do
        allow_any_instance_of(User).to receive(:can_show?)
          .with('individualized_educational_plans').and_return(false)
        plan = create(:individualized_educational_plan, classroom: classroom)

        get :index, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id }

        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET #show' do
    it 'reconstructs the version from its snapshot into the read-only form' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      version = create(:iep_version, iep: plan, active: true,
                                     content: { 'identification' => { 'student_name' => 'Aluno Congelado' } })

      get :show, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id, id: version.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:version)).to eq(version)
      expect(assigns(:individualized_educational_plan).student.name).to eq('Aluno Congelado')
    end

    it 'redirects with a warning and notifies when the snapshot is corrupted' do
      plan = create(:individualized_educational_plan, classroom: classroom)
      version = create(:iep_version, iep: plan, active: true, content: { 'identification' => {} })
      expect(Honeybadger).to receive(:notify)

      get :show, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id, id: version.id }

      expect(response).to redirect_to(individualized_educational_plan_versions_path(plan))
      expect(flash[:alert]).to be_present
    end
  end
end
