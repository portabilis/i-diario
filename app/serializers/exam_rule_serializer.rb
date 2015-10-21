class ExamRuleSerializer < ActiveModel::Serializer
  attributes :id, :frequency_type, :score_type, :opinion_type, :recovery_type
end
