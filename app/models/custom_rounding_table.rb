class CustomRoundingTable < ApplicationRecord
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  has_many :custom_rounding_table_values, dependent: :destroy

  has_and_belongs_to_many :unities, validate: false
  has_and_belongs_to_many :courses, join_table: 'custom_rounding_tables_courses'
  has_and_belongs_to_many :grades

  accepts_nested_attributes_for :custom_rounding_table_values, allow_destroy: true

  validates :name, uniqueness: true
  validates :name, :year, :unities, :courses, :grades, :rounded_avaliations, presence: true
  validate :check_custom_rounding_table_values

  scope :by_name, ->(name) { where('name ilike ?', "%#{name}%") }
  scope :by_unity, ->(unity_id) { joins(:unities).where(custom_rounding_tables_unities: { unity_id: unity_id }) }
  scope :by_course, lambda { |course_id|
    joins(:courses).where(custom_rounding_tables_courses: { course_id: course_id })
  }
  scope :by_grade, ->(grade_id) { joins(:grades).where(custom_rounding_tables_grades: { grade_id: grade_id }) }
  scope :by_avaliation, ->(avaliation) { where('? = ANY(rounded_avaliations)', avaliation) }
  scope :by_year, ->(year) { where(year: year) }
  scope :ordered, -> { order(:name) }
  scope :ordered_by_year, -> { order(arel_table[:year].desc) }

  def to_s
    name
  end

  def values
    custom_rounding_table_values
  end

  def check_custom_rounding_table_values
    actions = values.reject { |custom_rounding_table_value| custom_rounding_table_value.action.zero? }

    return if actions.empty? || actions.size.eql?(10)

    errors.add(:invalid_actions, 'O tipo de ação "Não utilizar arredondamento para esta casa decimal" não pode ser selecionado quando outras ações de arredondamento estiverem previstas.')
  end
end
