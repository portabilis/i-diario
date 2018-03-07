class ExamRulesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch(ano: years.first)["regras"]
  end

  protected

  def api
    IeducarApi::ExamRules.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|

        exam_rule = nil

        if exam_rule = exam_rules.find_by(api_code: record["id"])
          exam_rule.update(
            score_type: record["tipo_nota"],
            frequency_type: record["tipo_presenca"],
            recovery_type: record["tipo_recuperacao"],
            parallel_recovery_average: record["media_recuperacao_paralela"],
            opinion_type: record["parecer_descritivo"],
            final_recovery_maximum_score: record['nota_maxima_exame'],
            rounding_table_id: RoundingTable.find_by(api_code: record["tabela_arredondamento_id"]).try(:id),
            rounding_table_api_code: record["tabela_arredondamento_id"],
            rounding_table_concept_id: RoundingTable.find_by(api_code: record["tabela_arredondamento_id_conceitual"]).try(:id),
            rounding_table_concept_api_code: record["tabela_arredondamento_id_conceitual"]
          )
        else
          exam_rule = exam_rules.create(
            api_code: record["id"],
            score_type: record["tipo_nota"],
            frequency_type: record["tipo_presenca"],
            recovery_type: record["tipo_recuperacao"],
            parallel_recovery_average: record["media_recuperacao_paralela"],
            opinion_type: record["parecer_descritivo"],
            final_recovery_maximum_score: record['nota_maxima_exame'],
            rounding_table_id: RoundingTable.find_by(api_code: record["tabela_arredondamento_id"]).try(:id),
            rounding_table_api_code: record["tabela_arredondamento_id"],
            rounding_table_concept_id: RoundingTable.find_by(api_code: record["tabela_arredondamento_id_conceitual"]).try(:id),
            rounding_table_concept_api_code: record["tabela_arredondamento_id_conceitual"]
          )
        end

        record["turmas"].each do |api_classroom|
          if turma = Classroom.find_by(api_code: api_classroom["turma_id"])
            turma.update_attribute :exam_rule_id, exam_rule.id
          end
        end
      end
    end

    finish_worker('ExamRulesSynchronizer-' << years.first)
  end

  def exam_rules(klass = ExamRule)
    klass
  end
end
