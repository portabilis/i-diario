class LearningObjectivesAndSkillImport < ApplicationRecord
  include Audit

  audited

  belongs_to :user

  validates :step, :import_mode, presence: true

  has_enumeration_for :step, with: BnccSteps
  has_enumeration_for :import_mode, with: ImportModes

  def self.all_audits
    Audited::Audit.where(auditable_type: 'LearningObjectivesAndSkillImport').reorder(id: :desc)
  end
end
