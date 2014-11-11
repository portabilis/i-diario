# encoding: utf-8
require "rails_helper"

describe Navigation::TitleBuilder, :type => :service do
  subject { described_class.new(feature, show_icon, context) }

  let(:feature) { "dashboard" }

  describe "#build" do
      context "when icon is marked for show" do
        let(:show_icon) { true }

        context "and this feature is a ***REMOVED***" do
          let(:feature) { "dashboard" }

          it "returns the ***REMOVED*** icon and the ***REMOVED*** title text" do
            expect(subject.build).to eq "<i class=\"fa fa-fw fa-home\"></i> Dashboard"
          end
        end

        context "and this feature is a sub***REMOVED***" do
          let(:feature) { "***REMOVED***s" }

          it "returns the ***REMOVED*** icon and the sub***REMOVED*** title text" do
            expect(subject.build).to eq "<i class=\"fa fa-fw fa-cutlery\"></i> ***REMOVED***"
          end
        end
      end

      context "when icon is not marked for show" do
        let(:show_icon) { false }

        context "and this feature is a ***REMOVED***" do
          let(:feature) { "dashboard" }

          it "returns the ***REMOVED*** title text" do
            expect(subject.build).to eq "Dashboard"
          end
        end

        context "and this feature is a sub***REMOVED***" do
          let(:feature) { "***REMOVED***s" }

          it "returns the sub***REMOVED*** title text" do
            expect(subject.build).to eq "***REMOVED***"
          end
        end
      end
  end
end
