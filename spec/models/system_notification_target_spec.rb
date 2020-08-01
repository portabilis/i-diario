require 'rails_helper'

RSpec.describe SystemNotificationTarget, :type => :model do
  let(:unread_notifications) { double('unread_notifications') }

  context "Validations" do
    it { should validate_presence_of :system_notification }
    it { should validate_presence_of :user }
  end

  describe ".read!" do
    it "should update all records as readed" do
      allow(SystemNotificationTarget).to receive(:where).with(read: false).and_return(unread_notifications)
      expect(unread_notifications).to receive(:update_all).with(read: true)

      SystemNotificationTarget.read!
    end
  end
end
