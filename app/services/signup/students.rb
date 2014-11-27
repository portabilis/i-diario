module Signup
  class Students
    include ActiveModel::Model

    attr_accessor :email, :password, :password_confirmation

    validates :email, :password, :password_confirmation, presence: true
    validates :password, confirmation: true, length: { minimum: 8 }, allow_blank: true
    validates :email, email: true, allow_blank: true
    validate :uniqueness_of_email

    def save
      return false unless valid?

      User.transaction do
        user = User.create!(
          email: email,
          password: password,
          password_confirmation: password_confirmation,
          status: UserStatus::PENDING,
          kind: UserKind::STUDENT
        )

        user
      end
    end

    protected

    def uniqueness_of_email
      return if email.blank?

      if User.find_by(email: email)
        errors.add(:email, :taken)
      end
    end
  end
end
