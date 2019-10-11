require 'rails_helper'

RSpec.describe ContentRecord, type: :model do
  let(:current_school_calendar_fetcher) { create(:school_calendar, :with_one_step) }

  subject {
    build(
      :content_record,
      :with_contents
    )
  }

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:teacher) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity_id) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:record_date) }

    it 'should validate if record_date is today or before today' do
      allow(subject).to receive(:school_calendar).and_return(current_school_calendar_fetcher)
      today = Date.current
      subject.record_date = today + 1.day

      expect(subject).to_not be_valid
      expect(
        subject.errors.messages[:record_date]
      ).to include("deve ser igual ou antes de #{today.strftime('%d/%m/%Y')}")
    end
  end
end
