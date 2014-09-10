require 'spec_helper'

RSpec.describe ProfilesController, :type => :controller do
  describe "GET 'index'" do
    before do
      controller.stub(:authenticate_user!)
    end

    it "load all the profiles" do
      get :index, locale: 'pt-BR'

      expect(assigns(:profiles)).to eq Profile.all.order(:id)
    end
  end

  describe "PUT 'update'" do
    let(:profile) { profiles(:admin) }

    before do
      controller.stub(:authenticate_user!)
    end

    it "calls the ProfileUpdater service" do
      params = {"permission"=>"manage_users", "value"=>true, "id"=>"135138680",
                "controller"=>"profiles", "action"=>"update", "locale"=>"pt-BR"}

      updater = double(:updater, status: 201)

      ProfileUpdater.should_receive(:new).with(params).and_return(updater)

      updater.should_receive(:update)

      put :update, params.merge(locale: 'pt-BR')
    end
  end

  context "pt-BR routes" do
    it "routes to index" do
      expect(get: "perfis").to route_to(
        controller: "profiles",
        action: "index",
        locale: "pt-BR"
      )
    end

    it "routes to show" do
      expect(put: "perfis/1").to route_to(
        controller: "profiles",
        action: "update",
        id: "1",
        locale: "pt-BR"
      )
    end
  end
end
