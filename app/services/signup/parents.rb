module Signup
  class Parents
    include ActiveModel::Model

    attr_accessor :document, :student_code, :celphone, :email, :password,
      :password_confirmation, :students_attributes

    validates :document, :student_code, :celphone, :email, :password, :password_confirmation, presence: true
    validates :password, confirmation: true, allow_blank: true
    validates :email, email: true, allow_blank: true
    validate :uniqueness_of_document
    validate :uniqueness_of_email

    def students
      students = []

      (students_attributes || []).each do |_, attribute|
        next if attribute["selected"].blank?

        if student = Student.find_by(api_code: attribute["api_code"])
          students << student
        else
          students << Student.new(
            name: attribute["name"],
            api_code: attribute["api_code"],
            api: true
          )
        end
      end

      students
    end

    def save
      return false unless valid?

      User.transaction do
        user = User.create!(
          email: email,
          cpf: document,
          phone: celphone,
          password: password,
          password_confirmation: password_confirmation
        )

        students.each do |student|
          student.save!
          user.students << student
        end

        user
      end
    end

    protected

    def uniqueness_of_document
      return if document.blank?

      if User.find_by(cpf: document)
        errors.add(:document, :taken)
      end
    end

    def uniqueness_of_email
      return if email.blank?

      if User.find_by(email: email)
        errors.add(:email, :taken)
      end
    end
  end
end
