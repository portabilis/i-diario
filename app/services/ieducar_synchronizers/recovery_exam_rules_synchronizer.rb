class RecoveryExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch['regras-recuperacao']
  end

  protected

  def api
    IeducarApi::RecoveryExamRules.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        recovery_exam_rule = recovery_exam_rules.find_by(api_code: record['id'])

        if recovery_exam_rule.present?
          recovery_exam_rule.update(
            description: record['descricao'],
            steps: record['etapas_recuperadas'],
            average: record['media'],
            maximum_score: record['nota_maxima'],
            exam_rule_id: ExamRule.find_by(api_code: record['regra_avaliacao_id']).try(:id)
          )
        else
          recovery_exam_rules.create(
            api_code: record['id'],
            description: record['descricao'],
            steps: record['etapas_recuperadas'],
            average: record['media'],
            maximum_score: record['nota_maxima'],
            exam_rule_id: ExamRule.find_by(api_code: record['regra_avaliacao_id']).try(:id)
          )
        end
      end
    end
  end

  def recovery_exam_rules(klass = RecoveryExamRule)
    klass
  end
end
