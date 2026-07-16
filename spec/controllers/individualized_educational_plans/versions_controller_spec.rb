require 'rails_helper'

RSpec.describe IndividualizedEducationalPlans::VersionsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }

  around(:each) do |example|
    entity.using_connection { example.run }
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:require_current_teacher).and_return(true)
    allow(controller).to receive(:current_user_classroom).and_return(create(:classroom))
  end

  describe 'GET #index' do
    it 'lists the plan versions, most recent first' do
      plan = create(:individualized_educational_plan)
      older = create(:iep_version, iep: plan, published_at: 2.days.ago, active: false)
      newer = create(:iep_version, iep: plan, published_at: 1.day.ago, active: true)
      create(:iep_version) # versão de outro PEI, não deve aparecer

      get :index, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:versions)).to eq([newer, older])
    end
  end

  describe 'GET #show' do
    it 'presents the version from its snapshot' do
      plan = create(:individualized_educational_plan)
      version = create(:iep_version, iep: plan, active: true,
                                     content: { 'identification' => { 'student_name' => 'Aluno Congelado' } })

      get :show, params: { locale: 'pt-BR', individualized_educational_plan_id: plan.id, id: version.id }

      expect(response).to have_http_status(:ok)
      expect(assigns(:version)).to eq(version)
      expect(assigns(:presenter).identification['student_name']).to eq('Aluno Congelado')
    end
  end

  describe 'GET #show as pdf' do
    render_views

    it 'sends the version pdf rendered from the snapshot' do
      plan = create(:individualized_educational_plan)
      version = create(:iep_version, iep: plan, active: true,
                                     content: { 'identification' => { 'student_name' => 'Aluno Congelado' } })
      allow(ReportGenerator).to receive(:call).and_return(double(body: '%PDF-fake'))

      get :show, params: {
        locale: 'pt-BR', individualized_educational_plan_id: plan.id, id: version.id, format: :pdf
      }

      expect(response.body).to eq('%PDF-fake')
      expect(response.headers['Content-Type']).to include('application/pdf')
      expect(ReportGenerator).to have_received(:call).with(a_string_including('Aluno Congelado'))
    end
  end
end
