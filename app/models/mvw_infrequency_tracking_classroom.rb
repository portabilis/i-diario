class MvwInfrequencyTrackingClassroom < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :grade
  belongs_to :unity
  has_many :infrequency_trackings, dependent: :restrict_with_error

  scope :by_year, ->(year) { where(year: year) }
  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
  scope :by_grade_id, ->(grade_id) { where(grade_id: grade_id) }

  def readonly?
    true
  end

  def to_s
    description
  end
end
