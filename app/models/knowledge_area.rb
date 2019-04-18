class KnowledgeArea < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_many :disciplines, dependent: :destroy
  has_and_belongs_to_many :knowledge_area_content_records

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :by_discipline_id, ->(discipline_id) { joins(:disciplines).where(disciplines: { id: discipline_id }) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end

  def self.by_unity(unity)
    joins_classroom_and_teacher_discipline_classroom
      .where(classrooms: { unity_id: unity })
      .uniq
  end

  def self.by_teacher(teacher)
    joins_discipline_and_teacher_discipline_classroom
      .where(teacher_discipline_classrooms: { teacher_id: teacher })
      .uniq
  end

  def self.by_grade(grade)
    joins_classroom_and_teacher_discipline_classroom
      .where(classrooms: { grade_id: grade })
      .uniq
  end

  def self.joins_discipline_and_teacher_discipline_classroom
    joins(:disciplines)
      .joins(
        arel_table
          .join(TeacherDisciplineClassroom.arel_table)
          .on(
            TeacherDisciplineClassroom.arel_table[:discipline_id]
              .eq(Discipline.arel_table[:id])
          )
          .join_sources
      )
  end

  def self.joins_classroom_and_teacher_discipline_classroom
    joins_discipline_and_teacher_discipline_classroom
      .joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
  end

  private_class_method :joins_discipline_and_teacher_discipline_classroom
  private_class_method :joins_classroom_and_teacher_discipline_classroom
end
