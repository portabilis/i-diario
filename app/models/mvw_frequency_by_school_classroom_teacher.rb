class MvwFrequencyBySchoolClassroomTeacher < ApplicationRecord
  belongs_to :unity
  belongs_to :classroom
  belongs_to :teacher

  scope :by_year, ->(year) { where("EXTRACT(year FROM frequency_date) = #{year}") }
  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
  scope :by_teacher_id, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_date_between, ->(start_date, end_date) { where(frequency_date: (start_date.to_date..end_date.to_date)) }
end
