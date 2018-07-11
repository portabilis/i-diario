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

  describe "#add_error!" do
    it "saves the respective error" do
      subject = create(:ieducar_api_exam_posting)

      message = 'Erro qualquer'
      full_error_message = 'Exception X'

      subject.add_error!(message, full_error_message)

      expect(subject.full_error_message).to eq full_error_message
      expect(subject.error_message).to eq message
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
