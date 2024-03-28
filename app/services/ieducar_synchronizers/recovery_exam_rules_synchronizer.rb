class RecoveryExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_recovery_exam_rules(
      HashDecorator.new(
        api.fetch['regras-recuperacao']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::RecoveryExamRules
  end

  def update_recovery_exam_rules(recovery_exam_rules)
    recovery_exam_rules.each do |recovery_exam_rule_record|
      RecoveryExamRule.with_discarded.find_or_initialize_by(
        api_code: recovery_exam_rule_record.id
      ).tap do |recovery_exam_rule|
        recovery_exam_rule.description = recovery_exam_rule_record.descricao
        recovery_exam_rule.steps = recovery_exam_rule_record.etapas_recuperadas
        recovery_exam_rule.average = recovery_exam_rule_record.media
        recovery_exam_rule.maximum_score = recovery_exam_rule_record.nota_maxima
        recovery_exam_rule.exam_rule_id = exam_rule(recovery_exam_rule_record.regra_avaliacao_id).try(:id)
        recovery_exam_rule.save! if recovery_exam_rule.changed?

        recovery_exam_rule.discard_or_undiscard(recovery_exam_rule_record.deleted_at.present?)
      end
    end
  end
end
