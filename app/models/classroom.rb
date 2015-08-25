class Classroom < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :unity
  belongs_to :exam_rule
  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :description, :api_code, :unity_code, :year, presence: true
  validates :api_code, uniqueness: true

  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :by_unity_and_teacher, lambda { |unity_id, teacher_id| joins(:teacher_discipline_classrooms).where(unity_id: unity_id, teacher_discipline_classrooms: { teacher_id: teacher_id}) }
  scope :by_score_type, lambda { |score_type| where('exam_rules.score_type' => score_type).includes(:exam_rule) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }

  def to_s
    description
  end
end
