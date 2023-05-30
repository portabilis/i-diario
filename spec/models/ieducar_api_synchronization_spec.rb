require 'rails_helper'

RSpec.describe IeducarApiSynchronization, :type => :model do
  context "Associations" do
    it { should belong_to :ieducar_api_configuration }
    it { should belong_to :author }
  end

  context "Validations" do
    it { should validate_presence_of :ieducar_api_configuration }

    it do
      subject.ieducar_api_configuration = create(:ieducar_api_configuration)
      subject.status = ApiSynchronizationStatus::STARTED
      subject.save!
      is_expected.to validate_uniqueness_of(:ieducar_api_configuration_id).scoped_to(:status)
    end

    it do
      subject.ieducar_api_configuration = create(:ieducar_api_configuration)
      subject.status = ApiSynchronizationStatus::ERROR
      subject.save!
      is_expected.to_not validate_uniqueness_of(:ieducar_api_configuration_id).scoped_to(:status)
    end
  end

  describe '#mark_as_error!' do
    it 'should mark synchronization as error and set the error message' do
      subject = create(:ieducar_api_synchronization)

      subject.mark_as_error!('foo', 'bar')

      expect(subject.status).to eq ApiSynchronizationStatus::ERROR
      expect(subject.error_message).to eq 'foo'
      expect(subject.full_error_message).to eq 'bar'
    end
  end

  describe '#mark_as_completed!' do
    it 'should mark synchronization as completed' do
      subject = create(:ieducar_api_synchronization)

      subject.mark_as_completed!

      expect(subject.status).to eq ApiSynchronizationStatus::COMPLETED
    end
  end

  describe "#notified!" do
    it "marks synchronization as notified" do
      expect(subject).to receive(:update_column).with(:notified, true)

      subject.notified!
    end
  end
end
