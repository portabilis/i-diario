require 'rails_helper'

RSpec.describe SystemNotificationTarget, :type => :model do
  context "Validations" do
    it { should validate_presence_of :system_notification }
    it { should validate_presence_of :user }
  end

  describe ".read!" do
    it "should update all records as readed" do
      expect(SystemNotificationTarget).to receive(:update_all).with(read: true)

      SystemNotificationTarget.read!
    end
  end
end
