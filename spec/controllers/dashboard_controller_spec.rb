require 'spec_helper'

RSpec.describe DashboardController, :type => :controller do
  describe "GET 'index'" do
    fixtures :entities
    fixtures :users

    before do
      request.env['REQUEST_PATH'] = '/'
    end

    it "redirects to sign in path" do
      get :index, params: { locale: 'pt-BR' }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
