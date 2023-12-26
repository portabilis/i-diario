class LearningObjectivesAndSkill < ApplicationRecord
  include Audit

  audited
  acts_as_copy_target

  has_enumeration_for :step, with: BnccSteps, create_helpers: true
  has_enumeration_for :field_of_experience, with: BnccExperienceFields, create_helpers: true
  has_enumeration_for :discipline, with: BnccDisciplines, create_helpers: true

  scope :by_code, ->(code) { where('unaccent(code) ILIKE unaccent(?)', "%#{code}%") }
  scope :by_description, ->(description) { where('unaccent(description) ILIKE unaccent(?)', "%#{description}%") }
  scope :by_step, ->(step) { where(step: step) }
  scope :by_discipline, ->(discipline) { where(discipline: discipline) }
  scope :by_field_of_experience, ->(field_of_experience) { where(field_of_experience: field_of_experience) }
  scope :by_grade, ->(grade) { where('?  = ANY(grades)', grade) }
  scope :ordered, -> { order(:code) }

  validates :code, presence: true, uniqueness: true, length: { maximum: 50 }

  validates :description, presence: true
  validates :step, presence: true
  validates :grades, presence: true
end
