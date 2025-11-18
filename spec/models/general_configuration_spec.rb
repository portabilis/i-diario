require 'rails_helper'

RSpec.describe GeneralConfiguration, :type => :model do
  context "Validations" do
    it { should validate_presence_of :security_level }
    it { should validate_presence_of :allows_after_sales_relationship }

    it { should allow_value(SecurityLevels::BASIC).for(:security_level) }
    it { should allow_value(SecurityLevels::ADVANCED).for(:security_level) }
    it { should_not allow_value("nana").for(:security_level) }
  end

  describe ".current" do
    context "when it has a persited configuration" do
      it "return the first persited configuration" do
        general_configuration = general_configurations(:general_configuration)
        expect(GeneralConfiguration.current).to eq general_configuration
      end
    end
  end

  describe "#mark_with_error" do
    it "sets configuration backup's error message" do
      error = ""

      expect(subject).to receive(:update_columns).with(
        backup_status: ApiSynchronizationStatus::ERROR,
        error_message: error
      )

      subject.mark_with_error!(error)
    end
  end

  describe "#always_send_email_on_daily_frequency_registration" do
    it "defaults to false" do
      general_configuration = GeneralConfiguration.new
      expect(general_configuration.always_send_email_on_daily_frequency_registration).to eq(false)
    end

    it "can be set to true" do
      general_configuration = GeneralConfiguration.new
      general_configuration.always_send_email_on_daily_frequency_registration = true
      expect(general_configuration.always_send_email_on_daily_frequency_registration).to eq(true)
    end
  end
end
