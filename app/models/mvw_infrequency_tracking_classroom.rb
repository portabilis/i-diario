class MvwInfrequencyTrackingClassroom < ActiveRecord::Base
  self.primary_key = :id

  belongs_to :grade
  belongs_to :unity
  has_many :infrequency_trackings, dependent: :restrict_with_error

  scope :by_year, ->(year) { where(year: year) }

  def readonly?
    true
  end

  def to_s
    description
  end
end
