require 'rails_helper'

RSpec.describe User, type: :model do
  context 'associations' do
    it { expect(subject).to belong_to(:current_user_role).class_name('UserRole') }

    it { expect(subject).to have_many(:logins) }
    it { expect(subject).to have_many(:syncronizations) }
    it { expect(subject).to have_many(:***REMOVED***) }
    it { expect(subject).to have_many(:requested_***REMOVED***) }
    it { expect(subject).to have_many(:responsible_requested_***REMOVED***) }
    it { expect(subject).to have_many(:responsible_***REMOVED***) }
    it { expect(subject).to have_many(:responsible_***REMOVED***) }
    it { expect(subject).to have_many(:***REMOVED***s) }
    it { expect(subject).to have_many(:user_roles) }
    it { expect(subject).to have_and_belong_to_many(:students) }
  end

  context 'validations' do
    it { expect(subject).to validate_presence_of(:email) }
    it { expect(subject).to_not validate_presence_of(:student) }

    it { expect(subject).to allow_value('').for(:phone) }
    it { expect(subject).to allow_value('(33) 33445566').for(:phone) }
    it { expect(subject).to allow_value('(33) 334445556').for(:phone) }
    it { expect(subject).to_not allow_value('(33) 3344-5565').for(:phone) }
    it { expect(subject).to_not allow_value('(33) 3344-556').for(:phone) }
    it { expect(subject).to_not allow_value('(33) 3344556').for(:phone) }

    it { expect(subject).to allow_value('').for(:cpf) }
    it { expect(subject).to allow_value('531.880.033-58').for(:cpf) }
    it { expect(subject).to_not allow_value('531.880.033-5').for(:cpf) }
    it { expect(subject).to_not allow_value('531.880.033-587').for(:cpf) }

    it { expect(subject).to allow_value('admin@example.com').for(:email) }
    it { expect(subject).to_not allow_value('admin@examplecom', 'adminexample.com').for(:email).with_message('use apenas letras (a-z), números e pontos.') }

    describe '#user_roles' do
      it 'validates uniqueness of student role' do
        subject = User.new

        subject.user_roles << UserRole.new(role: roles(:student))
        subject.user_roles << UserRole.new(role: roles(:student))

        subject.valid?

        expect(subject.errors['user_roles']).to include('não é válido')
      end

      it 'validates uniqueness of parent role' do
        subject = User.new

        subject.user_roles << UserRole.new(role: roles(:parent))
        subject.user_roles << UserRole.new(role: roles(:parent))

        subject.valid?

        expect(subject.errors['user_roles']).to include('não é válido')
      end

      it 'accepts diferent roles' do
        subject = User.new

        subject.user_roles.build(user: subject, role: roles(:parent))
        subject.user_roles.build(user: subject, role: roles(:student))

        subject.valid?

        expect(subject.errors['user_roles']).to be_blank
      end
    end
  end

  describe '#authorize_email_and_sms' do
    it 'have false as default value' do
      expect(subject.authorize_email_and_sms).to eq(false)
    end
  end

  describe '#update_tracked_fields!' do
    it 'for every login it will log the user ip' do
      ip = '127.0.0.1'
      request = double(remote_ip: ip).as_null_object

      expect(subject.logins).to receive(:create!).with(sign_in_ip: ip)

      subject.update_tracked_fields!(request)
    end
  end

  describe '#to_s' do
    context 'without name' do
      before do
        subject.first_name = ''
        subject.email = 'foo@bar.com'
      end

      it 'returns the email' do
        expect(subject.to_s).to eql('foo@bar.com')
      end
    end

    context 'with name' do
      before do
        subject.first_name = 'Foo'
        subject.last_name = 'Bar'
      end

      it 'returns the name' do
        expect(subject.to_s).to eql('Foo Bar')
      end
    end
  end

  describe '#active_for_authentication?' do
    it 'can not authenticate if status is pending' do
      subject.status = UserStatus::PENDING

      expect(subject).to_not be_active_for_authentication
    end

    it 'can authenticate if status is actived' do
      subject.status = UserStatus::ACTIVED

      expect(subject).to be_active_for_authentication
    end
  end

  describe '#set_current_user_role!' do
    subject { create(:user_with_user_role) }

    it 'should update the #current_user_role_id' do
      expect { subject.set_current_user_role!(subject.user_roles.first.id) }.to change{ subject.current_user_role_id }.from(nil).to(subject.user_roles.first.id)
    end
  end
end