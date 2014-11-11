# encoding: utf-8
require "rails_helper"

describe Navigation::MenuRender, :type => :service do
  subject { described_class.new(context) }

  describe "#render" do
    context "when no ***REMOVED*** structure is informed" do
      let(:***REMOVED***s) { [] }

      it "returns the ***REMOVED*** without links" do
        expect(subject.render(***REMOVED***s)).to eq "<ul></ul>"
      end
    end

    context "when a ***REMOVED*** structure is informed" do
      context "and this structure no have sub***REMOVED***s" do
        context "and no have icon, path and css style informed" do 
          let(:***REMOVED***s) { [ { :type => 'dashboard', :css_class => [], :subnodes => [] } ] }

          it "returns this ***REMOVED*** with link but without icon, path and css style" do
            expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"\"><a href=\"#\"><span class=\"***REMOVED***-item-parent\">Dashboard</span></a></li></ul>"
          end
        end

        context "and have only icon informed" do
          let(:***REMOVED***s) { [ { :type => 'dashboard', :icon => 'fa-home', :css_class => [], :subnodes => [] } ] }

          it "returns this ***REMOVED*** with link but without path and css style" do
            expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-home\"></i> <span class=\"***REMOVED***-item-parent\">Dashboard</span></a></li></ul>"
          end
        end

        context "and have only path informed" do
          let(:***REMOVED***s) { [ { :type => 'dashboard', :path => 'root_path', :css_class => [], :subnodes => [] } ] }

          it "returns this ***REMOVED*** with link but without icon and css style" do
            expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"\"><a href=\"/\"><span class=\"***REMOVED***-item-parent\">Dashboard</span></a></li></ul>"
          end

        end

        context "and have only css style informed" do
          let(:***REMOVED***s) { [ { :type => 'dashboard', :css_class => ["open"], :subnodes => [] } ] }

          it "returns this ***REMOVED*** with link but without icon and path" do
            expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"open\"><a href=\"#\"><span class=\"***REMOVED***-item-parent\">Dashboard</span></a></li></ul>"
          end
        end
      end

      context "and this structure have sub***REMOVED***s" do
        let(:***REMOVED***s) do
          [
            {
              :type => '***REMOVED***',
              :icon => 'fa-cutlery',
              :css_class => [],
              :subnodes => [
                {
                  :type => '***REMOVED***s',
                  :path => '***REMOVED***s_path',
                  :css_class => [],
                  :subnodes => []
                },
                {
                  :type => '***REMOVED***',
                  :path => '***REMOVED***_path',
                  :css_class => [],
                  :subnodes => []
                }
              ]
            }
          ]
        end

        it "returns this ***REMOVED*** with links and sublinks" do 
          expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-cutlery\"></i> <span class=\"***REMOVED***-item-parent\">***REMOVED***</span> <b class=\"collapse-sign\"><em class=\"fa fa-plus-square-o\"></em></b></a> <ul><li class=\"\"><a href=\"/***REMOVED***\"><span class=\"***REMOVED***-item-parent\">***REMOVED***</span></a></li> <li class=\"\"><a href=\"/tipos-de-***REMOVED***\"><span class=\"***REMOVED***-item-parent\">Tipos de cardápios</span></a></li></ul></li></ul>"
        end
      end
    end
  end

  context "when many ***REMOVED***s structures are informed" do
    let(:***REMOVED***s) do
      [
        {
          :type => 'dashboard',
          :icon => 'fa-home',
          :path => 'root_path',
          :css_class => [],
          :subnodes => []
        },
        {
          :type => '***REMOVED***',
          :icon => 'fa-cutlery',
          :css_class => ['open'],
          :subnodes => [
            {
              :type => '***REMOVED***s',
              :path => '***REMOVED***s_path',
              :css_class => ['current'],
              :subnodes => []
            },
            {
              :type => '***REMOVED***',
              :path => '***REMOVED***_path',
              :css_class => [],
              :subnodes => []
            }
          ]
        }
      ]
    end

    it "returns the ***REMOVED*** with all links" do
      expect(subject.render(***REMOVED***s)).to eq "<ul><li class=\"\"><a href=\"/\"><i class=\"fa fa-lg fa-fw fa-home\"></i> <span class=\"***REMOVED***-item-parent\">Dashboard</span></a></li> <li class=\"open\"><a href=\"#\"><i class=\"fa fa-lg fa-fw fa-cutlery\"></i> <span class=\"***REMOVED***-item-parent\">***REMOVED***</span> <b class=\"collapse-sign\"><em class=\"fa fa-plus-square-o\"></em></b></a> <ul><li class=\"current\"><a href=\"/***REMOVED***\"><span class=\"***REMOVED***-item-parent\">***REMOVED***</span></a></li> <li class=\"\"><a href=\"/tipos-de-***REMOVED***\"><span class=\"***REMOVED***-item-parent\">Tipos de cardápios</span></a></li></ul></li></ul>"
    end
  end
end
