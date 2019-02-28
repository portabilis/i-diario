class RecoveryExamRule < ActiveRecord::Base
  include Discard::Model

  acts_as_copy_target

  audited

  belongs_to :exam_rule

  validates :api_code, :description, :exam_rule, :steps, :average, :maximum_score, presence: true
  validates :api_code, uniqueness: true
end
