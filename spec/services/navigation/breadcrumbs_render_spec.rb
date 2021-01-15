# encoding: utf-8
require "rails_helper"

describe Navigation::BreadcrumbsRender, type: :service do
  subject { described_class.new(context) }

  describe "#render" do
    context "when no menu is informed" do
      let(:menus) { [] }

      it "returns the breadcrumbs without links" do
        expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"></ol>"
      end
    end

    context "when one menu is informed" do
      context "and this menu does not have a icon and a path" do
        let(:menus) { [{ :type => 'dashboard' }] }

        it "returns a breadcrumbs link without icon and path" do
          expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"><li><a href=\"#\">Início</a></li></ol>"
        end
      end

      context "and this menu have a icon" do
        let(:menus) { [{ :type => 'dashboard', :icon => 'fa-home' }] }

        it "returns a breadcrumbs link with icon" do
          expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"><li><a href=\"#\"><i class=\"fa fa-home fa-fw\"></i> Início</a></li></ol>"
        end
      end

      context "and this menu have a path" do
        let(:menus) { [{ :type => 'dashboard', :path => 'root_path' }] }

        it "returns a breadcrumbs link with path" do
          expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li></ol>"
        end
      end

      context "and this menu have a icon and a path" do
        let(:menus) { [{ :type => 'dashboard', :path => 'root_path', :icon => 'fa-home'}] }

        it "returns a breadcrumbs link with icon and path" do
          expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\"><i class=\"fa fa-home fa-fw\"></i> Início</a></li></ol>"
        end
      end
    end

    context "when three menus are informed" do
      let(:menus) { [{ :type => 'begin', :path => 'root_path' }, { :type => 'configurations', :icon => 'fa-cog' }, { :type => 'roles', :path => 'roles_path' }] }

      it "returns three breadcrumbs links" do
        expect(subject.render(menus)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li> <li><a href=\"#\"><i class=\"fa fa-cog fa-fw\"></i> Configurações</a></li> <li><a href=\"/permissoes\">Permissões</a></li></ol>"
      end
    end
  end
end
