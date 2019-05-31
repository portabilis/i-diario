class ExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_exam_rules(
      HashDecorator.new(
        api.fetch['regras']
      )
    )
  end

  private

  def api_class
    IeducarApi::ExamRules
  end

  def update_exam_rules(exam_rules)
    exam_rules.each do |exam_rule_record|
      ExamRule.find_or_initialize_by(api_code: exam_rule_record.id).tap do |exam_rule|
        exam_rule.score_type = exam_rule_record.tipo_nota
        exam_rule.frequency_type = exam_rule_record.tipo_presenca
        exam_rule.recovery_type = exam_rule_record.tipo_recuperacao
        exam_rule.parallel_recovery_average = exam_rule_record.media_recuperacao_paralela
        exam_rule.opinion_type = exam_rule_record.parecer_descritivo
        exam_rule.final_recovery_maximum_score = exam_rule_record.nota_maxima_exame
        exam_rule.rounding_table_id = rounding_table(exam_rule_record.tabela_arredondamento_id).try(:id)
        exam_rule.rounding_table_api_code = exam_rule_record.tabela_arredondamento_id
        exam_rule.rounding_table_concept_id = rounding_table(
          exam_rule_record.tabela_arredondamento_id_conceitual
        ).try(:id)
        exam_rule.rounding_table_concept_api_code = exam_rule_record.tabela_arredondamento_id_conceitual
        exam_rule.save! if exam_rule.changed?
      end
    end
  end
end
