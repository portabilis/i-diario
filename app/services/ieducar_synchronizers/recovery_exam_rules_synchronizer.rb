class RecoveryExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['regras-recuperacao']
      )
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::RecoveryExamRules.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |recovery_exam_rule_record|
        recovery_exam_rule = RecoveryExamRule.find_by(api_code: recovery_exam_rule_record.id)
        exam_rule = ExamRule.find_by(api_code: recovery_exam_rule_record.regra_avaliacao_id)

        if recovery_exam_rule.present?
          recovery_exam_rule.update(
            description: recovery_exam_rule_record.descricao,
            steps: recovery_exam_rule_record.etapas_recuperadas,
            average: recovery_exam_rule_record.media,
            maximum_score: recovery_exam_rule_record.nota_maxima,
            exam_rule_id: exam_rule.try(:id)
          )
        else
          RecoveryExamRule.create(
            api_code: recovery_exam_rule_record.id,
            description: recovery_exam_rule_record.descricao,
            steps: recovery_exam_rule_record.etapas_recuperadas,
            average: recovery_exam_rule_record.media,
            maximum_score: recovery_exam_rule_record.nota_maxima,
            exam_rule_id: exam_rule.try(:id)
          )
        end
      end
    end
  end
end
