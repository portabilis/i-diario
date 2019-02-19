require "rails_helper"

describe Navigation, type: :service do
  let(:item) { :dashboard }
  let(:context){ double }

  subject { described_class }

  describe ".draw_breadcrumbs" do
    it "calls Navigation::BreadcrumbsBuilder.build" do
      expect(Navigation::BreadcrumbsBuilder).to receive(:build).with(item, context)

      subject.draw_breadcrumbs(item, context)
    end
  end

  describe ".draw_menus" do
    it "calls Navigation::MenuBuilder.build" do
      expect(Navigation::MenuBuilder).to receive(:build).with(item, context)

      subject.draw_menus(item, context)
    end
  end

  describe ".draw_title" do
    it "calls Navigation::TitleBuilder.build" do
      expect(Navigation::TitleBuilder).to receive(:build).with(item, true, context)

      subject.draw_title(item, true, context)
    end
  end
end
