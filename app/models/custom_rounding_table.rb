class CustomRoundingTable < ActiveRecord::Base
  acts_as_copy_target

  include Audit
  audited
  has_associated_audits

  has_many :custom_rounding_table_values, dependent: :destroy

  has_and_belongs_to_many :unities
  has_and_belongs_to_many :grades

  accepts_nested_attributes_for :custom_rounding_table_values, allow_destroy: true

  validates :name, uniqueness: true
  validates :name, :year, :unities, :grades, presence: true

  scope :by_name, lambda { |name| where('name ilike ?', "%#{name}%") }
  scope :by_unity, lambda { |unity_id| joins(:unities).where(custom_rounding_tables_unities: { unity_id: unity_id }) }
  scope :by_grade, lambda { |grade_id| joins(:grades).where(custom_rounding_tables_grades: { grade_id: grade_id }) }
  scope :by_year, lambda { |year| where(year: year) }
  scope :ordered, -> { order(:name) }

  def to_s
    name
  end

  def values
    custom_rounding_table_values
  end
end
