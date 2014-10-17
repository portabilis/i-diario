# encoding: utf-8
require 'rails_helper'

RSpec.describe User, :type => :model do
  context "Associations" do
    it { should have_many :logins }
    it { should have_many :syncronizations }
    it { should have_many :***REMOVED*** }
    it { should have_many :requested_***REMOVED*** }
    it { should have_many :responsible_requested_***REMOVED*** }
    it { should have_many :responsible_***REMOVED*** }
    it { should have_and_belong_to_many :students }
  end

  context "Validations" do
    it { should validate_presence_of(:email) }

    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 3344-5566').for(:phone) }
    it { should allow_value('(33) 33444-5556').for(:phone) }
    it { should_not allow_value('(33) 33445565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }

    it { should allow_value('').for(:cpf) }
    it { should allow_value('531.880.033-58').for(:cpf) }
    it { should_not allow_value('531.880.033-5').for(:cpf) }
    it { should_not allow_value('531.880.033-587').for(:cpf) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom', 'adminexample.com').for(:email).
         with_message("use apenas letras (a-z), números e pontos.") }
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
