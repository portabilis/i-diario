class Objective < ActiveRecord::Base
  audited
  has_associated_audits

  has_many :teaching_plans, dependent: :restrict_with_error

  validates :description, presence: true

  scope :ordered, -> { order(arel_table[:description].asc) }

  attr_accessor :is_editable

  def to_s
    description
  end
end
