class ExamRule < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :score_type, with: ScoreTypes
  has_enumeration_for :frequency_type, with: FrequencyTypes
  has_enumeration_for :opinion_type, with: OpinionTypes
  has_enumeration_for :recovery_type, with: RecoveryTypes

  belongs_to :rounding_table
  has_many :recovery_exam_rules

  validates :api_code, :score_type, :frequency_type, :opinion_type, :recovery_type, presence: true
  validates :api_code, uniqueness: true
end
