class Grade < ActiveRecord::Base
  include Discardable

  acts_as_copy_target

  audited

  belongs_to :course
  has_many :classrooms
  has_many :mvw_infrequency_tracking_classrooms

  has_and_belongs_to_many :custom_rounding_tables

  default_scope -> { kept }

  scope :by_unity, lambda { |unity| by_unity(unity) }
  scope :by_course, lambda { |course_id| where(course_id: course_id) }
  scope :by_teacher, lambda { |teacher| by_teacher(teacher) }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :by_year, lambda { |year| by_year(year)  }

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

  def self.by_year(year)
    joins(:classrooms).where(Classroom.arel_table[:year].eq(year))
  end

  def to_s
    description
  end
end
