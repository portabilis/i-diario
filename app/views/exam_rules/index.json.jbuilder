if @exam_rule.present?
  json.id @exam_rule.id
  json.frequency_type @exam_rule.frequency_type
  json.score_type @exam_rule.score_type
  json.opinion_type @exam_rule.opinion_type
end