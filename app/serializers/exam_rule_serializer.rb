class ExamRuleSerializer < ActiveModel::Serializer
  attributes :id, :frequency_type, :score_type, :opinion_type, :recovery_type

  has_one :rounding_table
end
