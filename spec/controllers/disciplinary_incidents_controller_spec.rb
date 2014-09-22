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
end
