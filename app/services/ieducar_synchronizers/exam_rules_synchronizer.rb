class ExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_exam_rules(
      HashDecorator.new(
        api.fetch(
          ano: years.first
        )['regras']
      )
    )

    finish_worker
  end

  def self.synchronize_in_batch!(synchronization, worker_batch, years = nil, _unity_api_code = nil, _entity_id = nil)
    years.each do |year|
      ExamRulesSynchronizer.synchronize!(
        synchronization,
        worker_batch,
        [year]
      )
    end
  end

  protected

  def worker_name
    "#{self.class}-#{years.first}"
  end

  def api_class
    IeducarApi::ExamRules
  end

  def update_exam_rules(exam_rules)
    ActiveRecord::Base.transaction do
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
          exam_rule.differentiated_exam_rule_api_code = exam_rule_record.regra_diferenciada_id
          exam_rule.differentiated_exam_rule_id = exam_rule(exam_rule_record.regra_diferenciada_id).try(:id)
          exam_rule.save! if exam_rule.changed?
        end

        update_classrooms_exam_rule(exam_rule, exam_rule_record.turmas)
      end
    end
  end

  def update_classrooms_exam_rule(exam_rule, classrooms)
    classrooms.each do |classroom_record|
      classroom = Classroom.find_by(api_code: classroom_record['turma_id'])

      classroom.update(exam_rule_id: exam_rule.id) if classroom.present?
    end
  end

  def rounding_table(rounding_table_id)
    @rounding_tables ||= {}
    @rounding_tables[rounding_table_id] ||= RoundingTable.find_by(api_code: rounding_table_id)
  end

  def exam_rule(exam_rule_id)
    @exam_rules ||= {}
    @exam_rules[exam_rule_id] ||= ExamRule.find_by(api_code: exam_rule_id)
  end
end
