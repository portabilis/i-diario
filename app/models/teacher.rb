class Teacher < ActiveRecord::Base
  acts_as_copy_target

  has_many :users
  has_many :teacher_discipline_classrooms, dependent: :destroy
  has_many :classrooms, through: :teacher_discipline_classrooms

  validates :name, :api_code, presence: true
  validates :api_code, uniqueness: true

  scope :by_active_teacher, -> { joins(:teacher_discipline_classrooms).active.order_by_name.uniq }
  scope :active, -> { where(TeacherDisciplineClassroom.arel_table[:active].eq(true)) }
  scope :order_by_name, -> { order(name: :asc)  }

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def to_s
    name
  end
end
