class MvwInfrequencyTrackingStudent < ActiveRecord::Base
  self.primary_key = :id

  has_many :infrequency_trackings, dependent: :restrict_with_error

  scope :by_year, ->(year) { where(year: year) }

  def readonly?
    true
  end

  def to_s
    name
  end
end
