require 'spec_helper'

RSpec.describe IeducarApiExamPostingsController, :type => :controller do
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
