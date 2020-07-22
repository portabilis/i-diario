# encoding: utf-8
require "rails_helper"

describe Navigation::TitleBuilder, type: :service do
  subject { described_class.new(feature, show_icon, context) }

  let(:feature) { "dashboard" }

  describe "#build" do
      context "when icon is marked for show" do
        let(:show_icon) { true }

        context "and this feature is a menu" do
          let(:feature) { "dashboard" }

          it "returns the menu icon and the menu title text" do
            expect(subject.build).to eq "<i class=\"fa fa-fw fa-home\"></i> Início"
          end
        end

        context "and this feature is a submenu" do
          let(:feature) { "roles" }

          it "returns the menu icon and the submenu title text" do
            expect(subject.build).to eq "<i class=\"fa fa-fw fa-cog\"></i> Permissões"
          end
        end
      end

      context "when icon is not marked for show" do
        let(:show_icon) { false }

        context "and this feature is a menu" do
          let(:feature) { "dashboard" }

          it "returns the menu title text" do
            expect(subject.build).to eq "Início"
          end
        end

        context "and this feature is a submenu" do
          let(:feature) { "roles" }

          it "returns the submenu title text" do
            expect(subject.build).to eq "Permissões"
          end
        end
      end
  end
end
