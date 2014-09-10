require 'spec_helper'

RSpec.describe DashboardController, :type => :controller do
  describe "GET 'index'" do
    fixtures :entities
    fixtures :users

    it "redirects to sign in path" do
      get :index, locale: 'pt-BR'

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
