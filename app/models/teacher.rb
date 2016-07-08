class Teacher < ActiveRecord::Base
  acts_as_copy_target

  has_many :users
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_discipline_classrooms

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :by_unity_id, lambda { |unity_id| by_unity_id(unity_id)}

  scope :order_by_name, -> { order(name: :asc) }

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
    joins(:teacher_discipline_classrooms).joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { unity_id: unity_id })
      .uniq
  end

  def to_s
    name
  end
end
