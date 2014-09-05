class Unity < ActiveRecord::Base
  belongs_to :author, class_name: "User"

  validates :author, :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{4}-[0-9]{4,5}\z/i }, allow_blank: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, allow_blank: true

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
