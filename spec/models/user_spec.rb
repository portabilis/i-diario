require 'rails_helper'

RSpec.describe User, :type => :model do
  context "Validations" do
    it { should validate_presence_of(:email) }

    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 3344-5566').for(:phone) }
    it { should_not allow_value('(33) 33445565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }

    it { should allow_value('').for(:cpf) }
    it { should allow_value('531.880.033-58').for(:cpf) }
    it { should_not allow_value('531.880.033-5').for(:cpf) }
    it { should_not allow_value('531.880.033-587').for(:cpf) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom').for(:email) }
    it { should_not allow_value('adminexample.com').for(:email) }
  end

  describe "#authorize_email_and_sms" do
    it 'have false as default value' do
      expect(subject.authorize_email_and_sms).to eq false
    end
  end

  describe "#update_tracked_fields!" do
    it "for every login it will log the user ip" do
      ip = "127.0.0.1"
      request = double(remote_ip: ip).as_null_object

      expect(subject.logins).to receive(:create!).with(sign_in_ip: ip)

      subject.update_tracked_fields!(request)
    end
  end
end
