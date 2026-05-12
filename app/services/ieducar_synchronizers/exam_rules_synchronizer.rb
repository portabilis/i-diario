class ExamRulesSynchronizer < BaseSynchronizer
  MAX_RETRIES = 3

  def synchronize!
    update_exam_rules(
      HashDecorator.new(
        api.fetch['regras']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::ExamRules
  end

  def update_exam_rules(exam_rules)
    preload_rounding_tables(
      (exam_rules.map(&:tabela_arredondamento_id) + exam_rules.map(&:tabela_arredondamento_id_conceitual)).compact
    )

    differentiated_exam_rules = []

    exam_rules.each do |exam_rule_record|
      retries = 0

      begin
        ExamRule.find_or_initialize_by(api_code: exam_rule_record.id.to_s).tap do |exam_rule|
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
          exam_rule.parallel_exams_calculation_type =
            exam_rule_record.tipo_calculo_recuperacao_paralela.to_i ||
            ParallelExamsCalculationTypes::SUBSTITUTION

          differentiated_exam_rules << [
            exam_rule_record.id,
            exam_rule_record.regra_diferenciada_id
          ]

          discard_descriptive_exams(exam_rule) if exam_rule.changed? && exam_rule.attribute_changed?("opinion_type")
          exam_rule.save!
        end
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
        raise e unless e.message.include?('Api code')

        retries += 1
        raise e if retries > MAX_RETRIES

        retry
      end
    end

    update_differentiated_exam_rules(differentiated_exam_rules)
  end

  def update_differentiated_exam_rules(differentiated_exam_rules)
    differentiated_exam_rules.each do |api_code, differentiated_api_code|
      exam_rule(api_code).tap do |exam_rule|
        exam_rule.differentiated_exam_rule_api_code = differentiated_api_code
        exam_rule.differentiated_exam_rule_id = exam_rule(differentiated_api_code).try(:id)
        exam_rule.save! if exam_rule.changed?
      end
    end
  end

  def discard_descriptive_exams(exam_rule)
    user_admin = User.find_by(admin: true)
    classroom_ids = ClassroomsGrade.where(exam_rule_id: exam_rule.id).pluck(:classroom_id).uniq

    Audited.audit_class.as_user(user_admin) do
      DescriptiveExam.where(classroom_id: classroom_ids)
                     .where.not(opinion_type: exam_rule.opinion_type)
                     .destroy_all
      DescriptiveExamStudent.by_classroom(classroom_ids).discard_all
    end
  end
end
