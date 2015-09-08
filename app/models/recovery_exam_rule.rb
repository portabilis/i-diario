class RecoveryExamRule < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :exam_rule

  validates :api_code, :description, :exam_rule, :steps, :average, :maximum_score, presence: true
  validates :api_code, uniqueness: true
end
