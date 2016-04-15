class ExamRule < ActiveRecord::Base
  acts_as_copy_target

  attr_accessor :allow_frequency_by_discipline

  has_enumeration_for :score_type, with: ScoreTypes
  has_enumeration_for :frequency_type, with: FrequencyTypes
  has_enumeration_for :opinion_type, with: OpinionTypes
  has_enumeration_for :recovery_type, with: RecoveryTypes

  belongs_to :rounding_table
  has_many :recovery_exam_rules

  validates :api_code,
    :score_type,
    :frequency_type,
    :opinion_type,
    :recovery_type,
    :final_recovery_maximum_score,
    presence: true
  validates :api_code, uniqueness: true

  scope :by_id, lambda { |id| where id: id }
  scope :by_frequency_type, lambda {|frequency_type| where frequency_type: frequency_type}

  def general_frequency_type?
    frequency_type == FrequencyTypes::GENERAL
  end

  def frequency_type_by_discipline?
    frequency_type == FrequencyTypes::BY_DISCIPLINE
  end
end
