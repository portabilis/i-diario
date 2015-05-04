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
    it { should have_many :responsible_***REMOVED*** }
    it { should have_many :***REMOVED***s }
    it { should have_many :user_roles }

    it { should have_and_belong_to_many :students }
  end

  context "Validations" do
    it { should validate_presence_of(:email) }
    it { should_not validate_presence_of(:student) }

    it { should allow_value('').for(:phone) }
    it { should allow_value('(33) 33445566').for(:phone) }
    it { should allow_value('(33) 334445556').for(:phone) }
    it { should_not allow_value('(33) 3344-5565').for(:phone) }
    it { should_not allow_value('(33) 3344-556').for(:phone) }
    it { should_not allow_value('(33) 3344556').for(:phone) }

    it { should allow_value('').for(:cpf) }
    it { should allow_value('531.880.033-58').for(:cpf) }
    it { should_not allow_value('531.880.033-5').for(:cpf) }
    it { should_not allow_value('531.880.033-587').for(:cpf) }

    it { should allow_value('admin@example.com').for(:email) }
    it { should_not allow_value('admin@examplecom', 'adminexample.com').for(:email).
         with_message("use apenas letras (a-z), números e pontos.") }

    describe "#user_roles" do
      it "validates uniqueness of student role" do
        subject = User.new

        subject.user_roles << UserRole.new(
          role: roles(:student)
        )
        subject.user_roles << UserRole.new(
          role: roles(:student)
        )

        subject.valid?

        expect(subject.errors["user_roles"]).to eq(["não é válido"])
      end

      it "validates uniqueness of parent role" do
        subject = User.new

        subject.user_roles << UserRole.new(
          role: roles(:parent)
        )
        subject.user_roles << UserRole.new(
          role: roles(:parent)
        )

        subject.valid?

        expect(subject.errors["user_roles"]).to eq(["não é válido"])
      end

      it "accepts diferent roles" do
        subject = User.new

        subject.user_roles << UserRole.new(
          role: roles(:parent)
        )
        subject.user_roles << UserRole.new(
          role: roles(:student)
        )

        subject.valid?

        expect(subject.errors["user_roles"]).to be_blank
      end
    end
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

  describe "#to_s" do
    context "without name" do
      before do
        subject.first_name = ""
        subject.email = 'foo@bar.com'
      end

      it "returns the email" do
        expect(subject.to_s).to eql "foo@bar.com"
      end
    end

    context "with name" do
      before do
        subject.first_name = "Foo"
        subject.last_name = "Bar"
      end

      it "returns the name" do
        expect(subject.to_s).to eql "Foo Bar"
      end
    end
  end

  describe "#active_for_authentication?" do
    it "can't authenticate if status is pending" do
      subject.status = UserStatus::PENDING

      expect(subject).to_not be_active_for_authentication
    end

    it "can authenticate if status is actived" do
      subject.status = UserStatus::ACTIVED

      expect(subject).to be_active_for_authentication
    end
  end
end
