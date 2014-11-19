require 'spec_helper'

RSpec.describe NotificationsController, :type => :controller do
  describe "GET 'edit'" do
    before do
      controller.stub(:authenticate_user!)
      controller.stub(:current_entity).and_return(Entity.first)
    end

    context "when no have Notification created" do
      before do
        ***REMOVED***.delete_all
        Notification.delete_all
      end

      xit "creates a new notification with blank attributes" do
        expect{
          get :edit, locale: 'pt-Br'
        }.to change{ Notification.count }.from(0).to(1)
      end

      xit "creates new notification settings with blank attributes" do
        expect{ 
          get :edit, locale: 'pt-Br'
        }.to change{ ***REMOVED***.count }.from(0).to(2)
      end
    end
  end

  context "pt-BR routes" do
    it "routes to edit" do
      expect(get: "notificacao/editar").to route_to(
        action: "edit",
        controller: "***REMOVED***",
        locale: "pt-BR"
      )
    end

    it "routes to update" do
      expect(put: "notificacao").to route_to(
        action: "update",
        controller: "***REMOVED***",
        locale: "pt-BR"
      )
    end
  end
end
