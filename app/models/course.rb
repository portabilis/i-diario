class Course < ActiveRecord::Base
  include Discardable

  acts_as_copy_target

  audited

  has_many :grades, dependent: :restrict_with_error

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  default_scope -> { kept }

  scope :by_unity, ->(unity) { by_unity(unity) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def self.by_unity(unity)
    joins(grades: [:classrooms]).where(classrooms: { unity_id: unity }).distinct
  end

  def to_s
    description
  end
end
