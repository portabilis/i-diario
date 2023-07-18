class Teacher < ApplicationRecord
  include Discardable
  acts_as_copy_target

  audited

  has_many :absence_justifications
  has_many :assumed_users, foreign_key: :assumed_teacher_id, class_name: 'User'
  has_many :classrooms, through: :teacher_discipline_classrooms
  has_many :content_records
  has_many :daily_frequencies, foreign_key: :owner_teacher_id
  has_many :ieducar_api_exam_postings
  has_many :lesson_plans
  has_many :observation_diary_records
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_many :teaching_plans
  has_many :transfer_notes
  has_many :users
  has_many :unities, -> { distinct }, through: :classrooms

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true
  validates :active, inclusion: { in: [true, false] }

  scope :by_id, ->(id) { where(id: id) }
  scope :by_unity_id, ->(unity_id) { by_unity_id(unity_id) }
  scope :by_year, ->(year) { filter_current_teachers_by_year(year) }
  scope :active, -> { active_query }
  scope :by_classroom, lambda { |classroom_id|
    joins(:teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: {
        classroom_id: classroom_id
      }
    )
  }
  scope :by_daily_frequency, lambda { |daily_frequency|
    joins(:teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: {
        classroom_id: daily_frequency.classroom_id,
        discipline_id: daily_frequency.discipline_id
      }
    )
  }
  scope :order_by_name, -> { order(name: :asc) }
  default_scope -> { kept }

  def self.active_query
    joins_teacher_discipline_classrooms.where(
      active: true
    ).distinct
  end

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def self.by_unity_id(unity_id)
    joins_teacher_discipline_classrooms.where(classrooms: { unity_id: unity_id })
                                       .active
                                       .distinct
  end

  def self.filter_current_teachers_by_year(year)
    joins_teacher_discipline_classrooms.where(
      classrooms: {year: year}
    )
  end

  def to_s
    name
  end

  def self.joins_teacher_discipline_classrooms
    joins(:teacher_discipline_classrooms).joins(
      arel_table.join(Classroom.arel_table)
        .on(
          Classroom.arel_table[:id]
            .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
        )
        .join_sources
    )
  end
end
