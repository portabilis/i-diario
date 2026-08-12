# A data de elaboração do PEI não pode ser futura, tem que estar no ano letivo do plano e precisa
# ser um DIA LETIVO no calendário da turma (o PEI é anual — não valida o período de lançamento da
# etapa). Retorna a mensagem do primeiro erro (i18n) ou nil se ok. Sem calendário na turma → não
#
# Mesma semântica do SchoolCalendarDayValidator, mas fora do model: a turma vem do perfil do
# usuário (não do plano), então a checagem roda no controller via este service.
class IndividualizedEducationalPlanElaborationDayCheck
  NOT_IN_PLAN_YEAR_KEY =
    'activerecord.errors.models.individualized_educational_plan.attributes.elaborated_at.not_in_plan_year'.freeze

  # year: ano letivo do plano; nil pula a regra de ano.
  def self.error_for(classroom, date, year: nil)
    new(classroom, date, year).error
  end

  def initialize(classroom, date, year = nil)
    @classroom = classroom
    @date = date
    @year = year
  end

  def error
    return if date.blank?
    return I18n.t('errors.messages.not_in_future') if date.to_date > Time.zone.today
    return I18n.t(NOT_IN_PLAN_YEAR_KEY, year: year) if year.present? && date.year != year.to_i
    return if classroom.blank?

    calendar = CurrentSchoolCalendarFetcher.new(classroom.unity, classroom, date.year).fetch
    return if calendar.blank?
    return if school_day?(calendar)

    step = calendar.steps.posting_date_after_and_before(date).first
    I18n.t(step ? 'errors.messages.not_school_calendar_day' : 'errors.messages.is_not_between_steps')
  end

  private

  attr_reader :classroom, :date, :year

  def school_day?(calendar)
    # [nil] quando a turma não tem série: valida só por eventos/etapas (mesmo sentinela do validador).
    grade_ids = classroom.grades.pluck(:id).presence || [nil]
    grade_ids.all? { |grade_id| calendar.day_allows_entry?(date, grade_id, classroom.id) }
  end
end
