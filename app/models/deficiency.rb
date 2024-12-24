class Deficiency < ApplicationRecord
  include Audit
  include Discardable

  audited

  has_many :deficiency_students, dependent: :destroy
  has_many :students, through: :deficiency_students

  validates :name, presence: true

  default_scope -> { kept }

  scope :ordered, -> { order(arel_table[:name].asc) }

  def to_s
    name
  end
end
