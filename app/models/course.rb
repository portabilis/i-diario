class Course < ActiveRecord::Base
  acts_as_copy_target

  has_many :grades

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true
  scope :by_unity, lambda { |unity| by_unity(unity) }

  scope :ordered, -> { order(arel_table[:description].asc) }

  def self.by_unity(unity)
    joins(grades: [:classrooms]).where(classrooms: { unity_id: unity }).uniq
  end

  def to_s
    description
  end
end
