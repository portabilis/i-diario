class ExamRule < ApplicationRecord
  acts_as_copy_target

  audited

  attr_accessor :allow_frequency_by_discipline

  has_enumeration_for :score_type, with: ScoreTypes
  has_enumeration_for :frequency_type, with: FrequencyTypes
  has_enumeration_for :opinion_type, with: OpinionTypes
  has_enumeration_for :recovery_type, with: RecoveryTypes
  has_enumeration_for :parallel_exams_calculation_type, with: ParallelExamsCalculationTypes

  belongs_to :rounding_table
  belongs_to :differentiated_exam_rule, class_name: 'ExamRule'
  belongs_to :rounding_table_concept, class_name: 'RoundingTable'
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
  scope :by_frequency_type, lambda { |frequency_type| where frequency_type: frequency_type }

  def allow_descriptive_exam?
    ["2", "3", "5", "6"].include?(opinion_type)
  end

  def conceptual_rounding_table
    if rounding_table_concept
      rounding_table_concept
    else
      rounding_table
    end
  end

  def calculate_school_term_average?
    parallel_exams_calculation_type == ParallelExamsCalculationTypes::AVERAGE
  end

  def calculate_school_term_sum?
    parallel_exams_calculation_type == ParallelExamsCalculationTypes::SUM
  end
end
