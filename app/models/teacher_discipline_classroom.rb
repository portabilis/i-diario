class TeacherDisciplineClassroom < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :teacher
  belongs_to :discipline
  belongs_to :classroom

  validates :teacher, :teacher_api_code, :discipline_api_code, :classroom_api_code, :year, presence: true

  scope :active, -> {
    where(arel_table[:active].eq('t'))
  }
  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_year, lambda { |year| where(year: year) }

end
