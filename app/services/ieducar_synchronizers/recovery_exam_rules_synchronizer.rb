class RecoveryExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_recovery_exam_rules(
      HashDecorator.new(
        api.fetch['regras-recuperacao']
      )
    )

    finish_worker
  end

  protected

  def api_class
    IeducarApi::RecoveryExamRules
  end

  def update_recovery_exam_rules(recovery_exam_rules)
    ActiveRecord::Base.transaction do
      recovery_exam_rules.each do |recovery_exam_rule_record|
        RecoveryExamRule.find_or_initialize_by(api_code: recovery_exam_rule_record.id).tap do |recovery_exam_rule|
          recovery_exam_rule.description = recovery_exam_rule_record.descricao
          recovery_exam_rule.steps = recovery_exam_rule_record.etapas_recuperadas
          recovery_exam_rule.average = recovery_exam_rule_record.media
          recovery_exam_rule.maximum_score = recovery_exam_rule_record.nota_maxima
          recovery_exam_rule.exam_rule_id = exam_rule(recovery_exam_rule_record.regra_avaliacao_id).try(:id)

          recovery_exam_rule.save! if recovery_exam_rule.changed?
        end
      end
    end
  end

  def exam_rule(exam_rule_id)
    @exam_rules ||= {}
    @exam_rules[exam_rule_id] ||= ExamRule.find_by(api_code: exam_rule_id)
  end
end
