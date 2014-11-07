require "rails_helper"

describe Navigation, :type => :service do
  let(:item) { :dashboard }
  let(:context){ double }

  subject { described_class }

  describe ".draw_breadcrumbs" do
    it "calls Navigation::BreadcrumbsBuilder.build" do
      expect(Navigation::BreadcrumbsBuilder).to receive(:build).with(item, context)

      subject.draw_breadcrumbs(item, context)
    end
  end

  describe ".draw_***REMOVED***s" do
    it "calls Navigation::MenuBuilder.build" do
      expect(Navigation::MenuBuilder).to receive(:build).with(item, context)

      subject.draw_***REMOVED***s(item, context)
    end
  end
end
