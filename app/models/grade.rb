class Grade < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :course
  has_many :classrooms

  scope :by_unity, lambda { |unity| by_unity(unity) }
  scope :by_course, lambda { |course_id| where(course_id: course_id) }
  scope :by_teacher, lambda { |teacher| by_teacher(teacher) }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :by_year, lambda { |year| joins(:classrooms).where('classroom.year = ?', year)  }

  validates :description, :api_code, :course, presence: true
  validates :api_code, uniqueness: true

  def self.by_unity(unity)
    joins(:classrooms).where(classrooms: { unity_id: unity }).uniq
  end

  def self.by_teacher(teacher)
    joins(:classrooms).joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
          .on(TeacherDisciplineClassroom.arel_table[:classroom_id].eq(Classroom.arel_table[:id]))
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher))
      .uniq
  end

  def to_s
    description
  end
end
