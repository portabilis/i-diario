module Api
  class EvaluationRecoveryResolver
    TYPE_LABELS = {
      'school_term_recovery' => 'Recuperação de Etapa',
      'final_recovery' => 'Exame Final'
    }.freeze

    def self.type_for(recovery_diary_record)
      if recovery_diary_record.avaliation_recovery_diary_record.present?
        'parallel_recovery'
      elsif recovery_diary_record.school_term_recovery_diary_record.present?
        'school_term_recovery'
      elsif recovery_diary_record.final_recovery_diary_record.present?
        'final_recovery'
      end
    end

    # steps_fetcher pode ser injetado pelo caller para reaproveitar uma única instância
    # (com seu próprio cache interno) entre várias chamadas na mesma turma, evitando
    # recriar StepsFetcher.new(classroom) - e reconsultar SchoolCalendar/steps - a cada registro.
    def self.step_for(recovery_diary_record, steps_fetcher: nil)
      fetcher = steps_fetcher || StepsFetcher.new(recovery_diary_record.classroom)

      case type_for(recovery_diary_record)
      when 'parallel_recovery'
        avaliation = recovery_diary_record.avaliation_recovery_diary_record.avaliation
        fetcher.step_by_date(avaliation.test_date)
      when 'school_term_recovery'
        school_term_recovery = recovery_diary_record.school_term_recovery_diary_record
        if school_term_recovery.step_id.present?
          fetcher.step_by_id(school_term_recovery.step_id)
        else
          fetcher.step(school_term_recovery.step_number)
        end
      when 'final_recovery'
        fetcher.last_step_by_year
      end
    end

    def self.maximum_score_for(recovery_diary_record)
      RecoveryDiaryRecordStudent.new(recovery_diary_record: recovery_diary_record).maximum_score
    end

    # A recuperação paralela é identificada pela avaliação que ela recupera; as demais
    # não têm avaliação de origem e são identificadas pelo tipo e pela disciplina.
    def self.title_for(recovery_diary_record)
      type = type_for(recovery_diary_record)

      return recovery_diary_record.avaliation_recovery_diary_record.avaliation.to_s if type == 'parallel_recovery'

      "#{TYPE_LABELS[type]} - #{recovery_diary_record.discipline}"
    end
  end
end
