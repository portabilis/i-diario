# encoding: utf-8
require "rails_helper"

describe Navigation::MenuRender, type: :service do
  let :current_user do
    User.new(admin: true)
  end

  subject { described_class.new current_user }

  describe "#render" do
    context "when no menu structure is informed" do
      let(:menus) { [] }

      it "returns the menu without links" do
        expect(subject.render(menus)).to eq "<ul></ul>"
      end
    end

    context "when a menu structure is informed" do
      context "and this structure no have submenus" do
        context "and no have icon, path and css style informed" do
          let(:menus) { [ { :type => 'dashboard', :css_class => [], :subnodes => [], :visible => true } ] }

          it "returns this menu with link but without icon, path and css style" do
            expect(subject.render(menus)).to eq "<ul><li class=\"\"><a href=\"#\"><span class=\"menu-item-parent\">Início</span></a></li></ul>"
          end
        end

        context "and have only icon informed" do
          let(:menus) { [ { :type => 'dashboard', :icon => 'fa-home', :css_class => [], :subnodes => [], :visible => true } ] }

          it "returns this menu with link but without path and css style" do
            expect(subject.render(menus)).to eq "<ul><li class=\"\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-home\"></i> <span class=\"menu-item-parent\">Início</span></a></li></ul>"
          end
        end

        context "and have only path informed" do
          let(:menus) { [ { :type => 'dashboard', :path => 'root_path', :css_class => [], :subnodes => [], :visible => true } ] }

          it "returns this menu with link but without icon and css style" do
            expect(subject.render(menus)).to eq "<ul><li class=\"\"><a href=\"/\"><span class=\"menu-item-parent\">Início</span></a></li></ul>"
          end

        end

        context "and have only css style informed" do
          let(:menus) { [ { :type => 'dashboard', :css_class => ["open"], :subnodes => [], :visible => true } ] }

          it "returns this menu with link but without icon and path" do
            expect(subject.render(menus)).to eq "<ul><li class=\"open\"><a href=\"#\"><span class=\"menu-item-parent\">Início</span></a></li></ul>"
          end
        end
      end

      context "and this structure have submenus" do
        let(:menus) do
          [
            {
              :type => 'configurations',
              :icon => 'fa-cog',
              :css_class => [],
              :subnodes => [
                {
                  :type => 'roles',
                  :path => 'roles_path',
                  :css_class => [],
                  :subnodes => []
                },
                {
                  :type => 'unities',
                  :path => 'unities_path',
                  :css_class => [],
                  :subnodes => []
                }
              ]
            }
          ]
        end

        it "returns this menu with links and sublinks" do
          expect(subject.render(menus)).to eq "<ul><li class=\"\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-cog\"></i> <span class=\"menu-item-parent\">Configurações</span></a> <ul><li class=\"\"><a href=\"/permissoes\"><span class=\"menu-item-parent\">Permissões</span></a></li> <li class=\"\"><a href=\"/unidades\"><span class=\"menu-item-parent\">Unidades</span></a></li></ul></li></ul>"
        end
      end
    end
  end

  context "when many menus structures are informed" do
    let(:menus) do
      [
        {
          :type => 'dashboard',
          :icon => 'fa-home',
          :path => 'root_path',
          :css_class => [],
          :subnodes => [],
          :visible => true
        },
        {
          :type => 'configurations',
          :icon => 'fa-cog',
          :css_class => ['open'],
          :subnodes => [
            {
              :type => 'roles',
              :path => 'roles_path',
              :css_class => ['current'],
              :subnodes => []
            },
            {
              :type => 'unities',
              :path => 'unities_path',
              :css_class => [],
              :subnodes => []
            }
          ]
        }
      ]
    end

    it "returns the menu with all links" do
      expect(subject.render(menus)).to eq "<ul><li class=\"\"><a href=\"/\"><i class=\"fa fa-lg fa-fw fa-home\"></i> <span class=\"menu-item-parent\">Início</span></a></li> <li class=\"open\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-cog\"></i> <span class=\"menu-item-parent\">Configurações</span></a> <ul><li class=\"current\"><a href=\"/permissoes\"><span class=\"menu-item-parent\">Permissões</span></a></li> <li class=\"\"><a href=\"/unidades\"><span class=\"menu-item-parent\">Unidades</span></a></li></ul></li></ul>"
    end
  end
end
