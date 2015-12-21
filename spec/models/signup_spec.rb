require 'rails_helper'

RSpec.describe Signup, type: :model do
  context 'validations' do
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

    context 'when parent role' do
      it 'should require document' do
        subject.parent_role = '1'

        expect(subject).to validate_presence_of(:document)
      end
    end

    context 'when not parent role' do
      it 'should not require document' do
        subject.parent_role = '0'

        expect(subject).not_to validate_presence_of(:document)
      end
    end

    context 'when parent role and with student' do
      it 'should require student_code' do
        subject.parent_role = '1'
        subject.without_student = '0'

        expect(subject).to validate_presence_of(:student_code)
      end
    end

    context 'when parent role and without student' do
      it 'should require student_code' do
        subject.parent_role = '1'
        subject.without_student = '1'

        expect(subject).not_to validate_presence_of(:student_code)
      end
    end

    context 'when not parent role' do
      it 'should require student_code' do
        subject.parent_role = '0'

        expect(subject).not_to validate_presence_of(:student_code)
      end
    end

    context 'when student role without email and without document' do
      it 'should require email or document' do
        subject.student_role = '1'
        subject.email = nil
        subject.document = nil

        subject.valid?

        expect(subject.errors[:base]).to include('Necessário informar e-mail ou CPF')
      end
    end

    context 'when student role with email and without document' do
      it 'should not require email or document' do
        subject.student_role = '1'
        subject.email = 'student@example.com'
        subject.document = nil

        subject.valid?

        expect(subject.errors[:base]).not_to include('Necessário informar e-mail ou CPF')
      end
    end

    context 'when student role without email and with document' do
      it 'should not require email or document' do
        subject.student_role = '1'
        subject.email = nil
        subject.document = Faker::CPF.pretty

        subject.valid?

        expect(subject.errors[:base]).not_to include('Necessário informar e-mail ou CPF')
      end
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
