require 'rails_helper'

RSpec.describe IeducarApiExamPosting, :type => :model do
  context "Associations" do
    it { should belong_to :ieducar_api_configuration }
    it { should belong_to :school_calendar_step }
    it { should belong_to :author }
  end

  context "Validations" do
    it { should validate_presence_of :ieducar_api_configuration }
    it { should validate_presence_of :school_calendar_step }
  end

  describe "#mark_as_error!" do
    it "should mark syncronization as error and set the error message" do
      message = double

      expect(subject).to receive(:update_columns).with(
        status: ApiSyncronizationStatus::ERROR,
        error_message: message
      )

      subject.mark_as_error!(message)
    end
  end

  describe "#mark_as_completed!" do
    it "should mark syncronization as completed" do
      message = double

      expect(subject).to receive(:update_columns).with(
        status: ApiSyncronizationStatus::COMPLETED,
        message: message
      )

      subject.mark_as_completed! message
    end
  end
end
