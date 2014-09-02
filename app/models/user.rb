class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  attr_accessor :credentials

  validates :phone, mask: { with: "(99) 9999-9999", message: :incorrect_format }, allow_blank: true

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, presence: true

  def self.find_for_authentication(conditions)
    credentials = conditions.fetch(:credentials)

    query = where(login: credentials, email: credentials, cpf: credentials, phone: credentials)
    where(query.where_values.map(&:to_sql).join(" OR ")).first
  end
end
