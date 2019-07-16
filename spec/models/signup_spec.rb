require 'rails_helper'

RSpec.describe Signup, type: :model do
  context 'validations' do
    it { expect(subject).to validate_presence_of(:first_name) }
    it { expect(subject).to validate_presence_of(:last_name) }
    it { expect(subject).to validate_presence_of(:password) }
    it { expect(subject).to validate_confirmation_of(:password) }
    it { expect(subject).to validate_presence_of(:password_confirmation) }

    it 'should validate uniqueness of document' do
      existing_user = create(:user)
      subject.document = existing_user.cpf

      subject.valid?

      expect(subject.errors[:document]).to include('já está em uso')
    end

    it 'should validate uniqueness of email' do
      existing_user = create(:user)
      subject.email = existing_user.email

      subject.valid?

      expect(subject.errors[:email]).to include('já está em uso')
    end

    context 'when employee role' do
      it 'should require email' do
        subject.employee_role = '1'

        expect(subject).to validate_presence_of(:email)
      end
    end

    context 'when not employee role' do
      it 'should not require email' do
        subject.employee_role = '0'

        expect(subject).not_to validate_presence_of(:email)
      end
    end
  end
end
