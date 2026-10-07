module Api
  class ListScheduledEvaluationsByClassroomService
    RECOVERY_DIARY_RECORD_INCLUDES = {
      recovery_diary_record: [
        :discipline,
        :school_term_recovery_diary_record,
        :final_recovery_diary_record,
        { avaliation_recovery_diary_record: :avaliation }
      ]
    }.freeze

    def self.call(classroom_api_code:, year:, step_number: nil, discipline_api_code: nil, after_date: nil)
      new(
        classroom_api_code: classroom_api_code,
        year: year,
        step_number: step_number,
        discipline_api_code: discipline_api_code,
        after_date: after_date
      ).call
    end

    def initialize(classroom_api_code:, year:, step_number: nil, discipline_api_code: nil, after_date: nil)
      @classroom_api_code = classroom_api_code
      @year = year
      @step_number = step_number
      @discipline_api_code = discipline_api_code
      @after_date = after_date
    end

    def call
      # RecoveryDiaryRecordStudent#maximum_score, TestSettingFetcher e Stepable#step (lógica de
      # domínio compartilhada, fora do controle deste service) instanciam um StepsFetcher novo a
      # cada chamada, reconsultando SchoolCalendar/SchoolCalendarStep por registro. Como todos os
      # itens desta resposta pertencem à mesma turma, o cache de query do Rails deduplica essas
      # consultas idênticas sem precisar alterar esse código compartilhado.
      ActiveRecord::Base.connection.cache { build_response }
    end

    private

    attr_reader :classroom_api_code, :year, :step_number, :discipline_api_code, :after_date

    def build_response
      items = []

      unless step_number.present? && step.blank?
        items += avaliations.map { |avaliation| build_avaliation_item(avaliation) }
        items += avaliation_recoveries.map { |record| build_recovery_item(record.recovery_diary_record) }
        items += school_term_recoveries.map { |record| build_recovery_item(record.recovery_diary_record) }
        if final_recovery_matches_step?
          items += final_recoveries.map { |record| build_recovery_item(record.recovery_diary_record) }
        end
      end

      {
        data: items.sort_by { |item| item[:date] },
        meta: { classroom_id: classroom_api_code, year: year, step_number: step&.step_number }
      }
    end

    def classroom
      @classroom ||= Classroom.find_by!(year: year, api_code: classroom_api_code)
    end

    def discipline
      return nil if discipline_api_code.blank?

      @discipline ||= Discipline.find_by!(api_code: discipline_api_code)
    end

    def steps_fetcher
      @steps_fetcher ||= StepsFetcher.new(classroom)
    end

    def step
      return nil if step_number.blank?

      @step ||= steps_fetcher.step(step_number)
    end

    def final_recovery_matches_step?
      return true if step_number.blank?

      last_step = steps_fetcher.last_step_by_year
      last_step.present? && last_step.step_number == step_number.to_i
    end

    def avaliations
      scope = Avaliation.by_classroom_id(classroom.id).includes(:discipline, :test_setting, :test_setting_test)
      scope = scope.by_discipline_id(discipline.id) if discipline
      filter_by_test_date(scope)
    end

    def avaliation_recoveries
      scope = AvaliationRecoveryDiaryRecord.by_classroom_id(classroom.id).includes(RECOVERY_DIARY_RECORD_INCLUDES)
      scope = scope.by_discipline_id(discipline.id) if discipline
      filter_by_test_date(scope)
    end

    def school_term_recoveries
      scope = SchoolTermRecoveryDiaryRecord.by_classroom_id(classroom.id).includes(RECOVERY_DIARY_RECORD_INCLUDES)
      scope = scope.by_discipline_id(discipline.id) if discipline
      scope = scope.by_step_number(step_number.to_i) if step_number.present?
      filter_by_recorded_at_after(scope)
    end

    def final_recoveries
      scope = FinalRecoveryDiaryRecord.by_classroom_id(classroom.id).includes(RECOVERY_DIARY_RECORD_INCLUDES)
      scope = scope.by_discipline_id(discipline.id) if discipline
      filter_by_recorded_at_after(scope)
    end

    def filter_by_test_date(scope)
      scope = scope.by_test_date_between(step.start_at, step.end_at) if step
      scope = scope.by_test_date_after(after_date) if after_date.present?
      scope
    end

    def filter_by_recorded_at_after(scope)
      return scope unless after_date.present?

      scope.by_recorded_at_after(after_date)
    end

    def build_avaliation_item(avaliation)
      {
        id: avaliation.id,
        type: 'numerical_exam',
        date: avaliation.test_date,
        title: avaliation.to_s,
        discipline: discipline_json(avaliation.discipline),
        step: step_json(steps_fetcher.step_by_date(avaliation.test_date)),
        score_type: 'numeric',
        maximum_score: MaximumScoreFetcher.new(avaliation).maximum_score
      }
    end

    def build_recovery_item(recovery_diary_record)
      {
        id: recovery_diary_record.id,
        type: EvaluationRecoveryResolver.type_for(recovery_diary_record),
        date: recovery_diary_record.recorded_at,
        title: EvaluationRecoveryResolver.title_for(recovery_diary_record),
        discipline: discipline_json(recovery_diary_record.discipline),
        step: step_json(EvaluationRecoveryResolver.step_for(recovery_diary_record, steps_fetcher: steps_fetcher)),
        score_type: 'numeric',
        maximum_score: EvaluationRecoveryResolver.maximum_score_for(recovery_diary_record)
      }
    end

    def discipline_json(discipline)
      { id: discipline.api_code, name: discipline.to_s }
    end

    def step_json(step)
      return nil unless step

      { number: step.step_number, name: step.school_term, start_at: step.start_at, end_at: step.end_at }
    end
  end
end
