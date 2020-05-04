class UnitySchoolDay < ActiveRecord::Base
  belongs_to :unity

  scope :by_year, ->(year) { where("EXTRACT(year FROM school_day) = #{year}") }
  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
  scope :by_date_between, ->(start_date, end_date) { where(school_day: (start_date..end_date)) }
end
