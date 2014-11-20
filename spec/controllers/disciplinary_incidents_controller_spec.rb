# encoding: utf-8
require 'spec_helper'

RSpec.describe DisciplinaryIncidentsController, :type => :controller do
  context "pt-BR routes" do
    it "routes to index" do
      expect(get: "ocorrencias-disciplinares").to route_to(
        controller: "disciplinary_incidents",
        action: "index",
        locale: "pt-BR"
      )
    end
  end

  describe "#index" do
    context "without students" do
      it "should redirect to root_path and display the error message" do
        user = users(:mary_jane)

        controller.stub(:current_user).and_return(user)
        controller.stub(:authenticate_user!)

        get :index, locale: 'pt-BR'

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/É necessário informar os códigos dos alunos: aluno_id/)
      end
    end
  end
end
