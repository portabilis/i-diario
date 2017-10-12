class Content < ActiveRecord::Base
  include Audit

  audited
  has_associated_audits

  acts_as_copy_target

  has_many :teaching_plans, dependent: :restrict_with_error
  has_many :lesson_plans, dependent: :restrict_with_error
  has_many :content_records, dependent: :restrict_with_error

  validates :description, presence: true

  scope :by_description, lambda { |description| where(' contents.description ILIKE ? ', '%'+description+'%') }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :order_by_id, -> { order(id: :asc) }

  def to_s
    description
  end
end
