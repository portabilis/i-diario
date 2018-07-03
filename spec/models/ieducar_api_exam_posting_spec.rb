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
    it "should mark synchronization as error and set the error message" do
      message = double
      full_error_message = double

      expect(subject).to receive(:update_columns).with(
        status: ApiSynchronizationStatus::ERROR,
        error_message: message,
        full_error_message: full_error_message,
      )

      subject.mark_as_error!(message, full_error_message)
    end
  end

  describe "#mark_as_completed!" do
    it "should mark synchronization as completed" do
      message = double

      expect(subject).to receive(:update_columns).with(
        status: ApiSynchronizationStatus::COMPLETED,
        message: message
      )

      subject.mark_as_completed! message
    end
  end
end
