class ExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch(ano: years.first)['regras']
  end

  def self.synchronize_in_batch!(synchronization, worker_batch, years = nil, unity_api_code = nil, entity_id = nil)
    super do
      years.each do |year|
        ExamRulesSynchronizer.new(
          synchronization,
          worker_batch,
          [year],
          unity_api_code,
          entity_id
        ).synchronize!
      end
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
      collection.each do |record|
        exam_rule = exam_rules.find_by(api_code: record['id'])

        if exam_rule.present?
          exam_rule.update(
            score_type: record['tipo_nota'],
            frequency_type: record['tipo_presenca'],
            recovery_type: record['tipo_recuperacao'],
            parallel_recovery_average: record['media_recuperacao_paralela'],
            opinion_type: record['parecer_descritivo'],
            final_recovery_maximum_score: record['nota_maxima_exame'],
            rounding_table_id: RoundingTable.find_by(api_code: record['tabela_arredondamento_id']).try(:id),
            rounding_table_api_code: record['tabela_arredondamento_id'],
            rounding_table_concept_id: RoundingTable.find_by(api_code: record['tabela_arredondamento_id_conceitual']).try(:id),
            rounding_table_concept_api_code: record['tabela_arredondamento_id_conceitual'],
            differentiated_exam_rule_api_code: record['regra_diferenciada_id'],
            differentiated_exam_rule_id: ExamRule.find_by(api_code: record['regra_diferenciada_id']).try(:id)
          )
        else
          exam_rule = exam_rules.create(
            api_code: record['id'],
            score_type: record['tipo_nota'],
            frequency_type: record['tipo_presenca'],
            recovery_type: record['tipo_recuperacao'],
            parallel_recovery_average: record['media_recuperacao_paralela'],
            opinion_type: record['parecer_descritivo'],
            final_recovery_maximum_score: record['nota_maxima_exame'],
            rounding_table_id: RoundingTable.find_by(api_code: record['tabela_arredondamento_id']).try(:id),
            rounding_table_api_code: record['tabela_arredondamento_id'],
            rounding_table_concept_id: RoundingTable.find_by(api_code: record['tabela_arredondamento_id_conceitual']).try(:id),
            rounding_table_concept_api_code: record['tabela_arredondamento_id_conceitual'],
            differentiated_exam_rule_api_code: record['regra_diferenciada_id'],
            differentiated_exam_rule_id: ExamRule.find_by(api_code: record['regra_diferenciada_id']).try(:id)
          )
        end

        record['turmas'].each do |api_classroom|
          turma = Classroom.find_by(api_code: api_classroom['turma_id'])

          turma.update_attribute(:exam_rule_id, exam_rule.id) if turma.present?
        end
      end
    end
  end

  def exam_rules(klass = ExamRule)
    klass
  end
end
