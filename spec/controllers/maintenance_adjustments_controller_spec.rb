require 'rails_helper'

RSpec.describe MaintenanceAdjustmentsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:unity) { create(:unity) }
  let(:current_school_year) { Date.current.year }
  let(:user) do
    create(
      :user,
      :with_user_role_administrator,
      admin: true,
      current_unity_id: unity.id,
      current_school_year: current_school_year
    )
  end

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    request.env['REQUEST_PATH'] = ''
    unity
  end

  describe 'GET #new' do
    it 'renders the form even when the model does not expose error_message' do
      get :new, params: { locale: 'pt-BR' }

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:new)
      expect(assigns(:maintenance_adjustment).status).to eq(MaintenanceAdjustmentStatus::PENDING)
    end
  end
end
