# encoding: utf-8
require "rails_helper"

describe Navigation::BreadcrumbsRender, :type => :service do
  subject { described_class.new(context) }

  describe "#render" do
    context "when no ***REMOVED*** is informed" do
      let(:***REMOVED***s) { [] }

      it "returns the breadcrumbs without links" do
        expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"></ol>"
      end
    end

    context "when one ***REMOVED*** is informed" do
      context "and this ***REMOVED*** does not have a icon and a path" do
        let(:***REMOVED***s) { [{ :type => 'dashboard' }] }

        it "returns a breadcrumbs link without icon and path" do
          expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"><li><a href=\"#\">Dashboard</a></li></ol>"
        end
      end

      context "and this ***REMOVED*** have a icon" do
        let(:***REMOVED***s) { [{ :type => 'dashboard', :icon => 'fa-home' }] }

        it "returns a breadcrumbs link with icon" do
          expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"><li><a href=\"#\"><i class=\"fa fa-home fa-fw\"></i> Dashboard</a></li></ol>"
        end
      end

      context "and this ***REMOVED*** have a path" do
        let(:***REMOVED***s) { [{ :type => 'dashboard', :path => 'root_path' }] }

        it "returns a breadcrumbs link with path" do
          expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Dashboard</a></li></ol>"
        end
      end

      context "and this ***REMOVED*** have a icon and a path" do
        let(:***REMOVED***s) { [{ :type => 'dashboard', :path => 'root_path', :icon => 'fa-home'}] }

        it "returns a breadcrumbs link with icon and path" do
          expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\"><i class=\"fa fa-home fa-fw\"></i> Dashboard</a></li></ol>"
        end
      end
    end

    context "when three ***REMOVED***s are informed" do
      let(:***REMOVED***s) { [{ :type => 'begin', :path => 'root_path' }, { :type => '***REMOVED***', :icon => 'fa-cutlery' }, { :type => '***REMOVED***s', :path => '***REMOVED***s_path' }] }

      it "returns three breadcrumbs links" do
        expect(subject.render(***REMOVED***s)).to eq "<ol class=\"breadcrumb\"><li><a href=\"/\">Início</a></li> <li><a href=\"#\"><i class=\"fa fa-cutlery fa-fw\"></i> ***REMOVED***</a></li> <li><a href=\"/***REMOVED***\">***REMOVED***</a></li></ol>"
      end
    end
  end
end
