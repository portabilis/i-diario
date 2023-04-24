require 'rails_helper'

RSpec.describe BootstrapFlashHelper, type: :helper do
  describe "#bootstrap_flash" do

    it "returns empty with no params" do
      expect(helper.bootstrap_flash).to be_empty
    end

    it "returns empty when type does not exit" do
      allow(helper).to receive(:flash).and_return({ test: 'test-message'})
      expect(helper.bootstrap_flash).to be_empty
    end

    it "returns html with success message" do
      allow(helper).to receive(:flash).and_return({ success: 'test-message'})
      expect(helper.bootstrap_flash).to include('success')
      expect(helper.bootstrap_flash).to include('test-message')
    end

    it "returns html with info message" do
      allow(helper).to receive(:flash).and_return({ info: 'test-message'})
      expect(helper.bootstrap_flash).to include('info')
      expect(helper.bootstrap_flash).to include('test-message')
    end

    it "returns html with warning message" do
      allow(helper).to receive(:flash).and_return({ warning: 'test-message'})
      expect(helper.bootstrap_flash).to include('warning')
      expect(helper.bootstrap_flash).to include('test-message')
    end

    it "returns html with danger message" do
      allow(helper).to receive(:flash).and_return({ danger: 'test-message'})
      expect(helper.bootstrap_flash).to include('danger')
      expect(helper.bootstrap_flash).to include('test-message')
    end
  end
end
