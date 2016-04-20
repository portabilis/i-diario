class ExamRuleSerializer < ActiveModel::Serializer
  attributes :id, :frequency_type, :score_type, :opinion_type, :recovery_type, :allow_frequency_by_discipline

  has_one :rounding_table
end
