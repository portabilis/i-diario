class Content < ActiveRecord::Base
  acts_as_copy_target

  has_and_belongs_to_many :teaching_plans, dependent: :destroy
  has_and_belongs_to_many :lesson_plans, dependent: :destroy
  has_and_belongs_to_many :content_records, dependent: :destroy

  validates :description, presence: true

  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end
end
