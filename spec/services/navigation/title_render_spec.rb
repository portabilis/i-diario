require "rails_helper"

describe Navigation::TitleRender, type: :service do
  subject { described_class.new(context) }

  let(:show_icon){ true }
  let(:params) do
    { :icon => "fa-home", :type => "dashboard" }
  end

  describe "#render" do
    context "when icon is marked to be show" do
      it "returns the icon and the title name" do
        expect(subject.render(params, show_icon)).to eq "<i class=\"fa fa-fw fa-home\"></i> Início"
      end
    end

    context "when icon is not marked to be show" do
      let(:show_icon){ false }

      it "this not returns the icon and the title name" do
        expect(subject.render(params, show_icon)).to eq "Início"
      end
    end
  end
end
