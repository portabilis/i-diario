class ExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch(
          ano: years.first
        )['regras']
      )
    )

    finish_worker
  end

  def self.synchronize_in_batch!(synchronization, worker_batch, years = nil, _unity_api_code = nil, entity_id = nil)
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

  def api
    IeducarApi::ExamRules.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |exam_rule_record|
        exam_rule = exam_rules.find_by(api_code: exam_rule_record.id)

        rounding_table = RoundingTable.find_by(api_code: exam_rule_record.tabela_arredondamento_id)
        conceptual_rounding_table = RoundingTable.find_by(api_code: exam_rule_record.tabela_arredondamento_id_conceitual)
        differentiated_exam_rule = ExamRule.find_by(api_code: exam_rule_record.regra_diferenciada_id)

        if exam_rule.present?
          exam_rule.update(
            score_type: exam_rule_record.tipo_nota,
            frequency_type: exam_rule_record.tipo_presenca,
            recovery_type: exam_rule_record.tipo_recuperacao,
            parallel_recovery_average: exam_rule_record.media_recuperacao_paralela,
            opinion_type: exam_rule_record.parecer_descritivo,
            final_recovery_maximum_score: exam_rule_record.nota_maxima_exame,
            rounding_table_id: rounding_table.try(:id),
            rounding_table_api_code: exam_rule_record.tabela_arredondamento_id,
            rounding_table_concept_id: conceptual_rounding_table.try(:id),
            rounding_table_concept_api_code: exam_rule_record.tabela_arredondamento_id_conceitual,
            differentiated_exam_rule_api_code: exam_rule_record.regra_diferenciada_id,
            differentiated_exam_rule_id: differentiated_exam_rule.try(:id)
          )
        else
          exam_rule = exam_rules.create(
            api_code: exam_rule_record.id,
            score_type: exam_rule_record.tipo_nota,
            frequency_type: exam_rule_record.tipo_presenca,
            recovery_type: exam_rule_record.tipo_recuperacao,
            parallel_recovery_average: exam_rule_record.media_recuperacao_paralela,
            opinion_type: exam_rule_record.parecer_descritivo,
            final_recovery_maximum_score: exam_rule_record.nota_maxima_exame,
            rounding_table_id: rounding_table.try(:id),
            rounding_table_api_code: exam_rule_record.tabela_arredondamento_id,
            rounding_table_concept_id: conceptual_rounding_table.try(:id),
            rounding_table_concept_api_code: exam_rule_record.tabela_arredondamento_id_conceitual,
            differentiated_exam_rule_api_code: exam_rule_record.regra_diferenciada_id,
            differentiated_exam_rule_id: differentiated_exam_rule.try(:id)
          )
        end

        exam_rule_record.turmas.each do |classroom_record|
          classroom = Classroom.find_by(api_code: classroom_record['turma_id'])

          classroom.update(exam_rule_id: exam_rule.id) if classroom.present?
        end
      end
    end
  end

  def exam_rules(klass = ExamRule)
    klass
  end
end
