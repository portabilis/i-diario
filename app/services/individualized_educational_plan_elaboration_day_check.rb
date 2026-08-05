# A data de elaboração do PEI precisa ser um DIA LETIVO no calendário da turma (o PEI é anual —
# não valida o período de lançamento da etapa). Retorna a mensagem de erro (i18n) ou nil se ok.
# Sem calendário na turma → não valida. Sem bypass de admin: vale para todos.
#
# Mesma semântica do SchoolCalendarDayValidator, mas fora do model: a turma vem do perfil do
# usuário (não do plano), então a checagem roda no controller via este service.
class IndividualizedEducationalPlanElaborationDayCheck
  def self.error_for(classroom, date)
    new(classroom, date).error
  end

  def initialize(classroom, date)
    @classroom = classroom
    @date = date
  end

  def error
    return if date.blank? || classroom.blank?

    calendar = CurrentSchoolCalendarFetcher.new(classroom.unity, classroom, date.year).fetch
    return if calendar.blank?
    return if school_day?(calendar)

    step = calendar.steps.posting_date_after_and_before(date).first
    I18n.t(step ? 'errors.messages.not_school_calendar_day' : 'errors.messages.is_not_between_steps')
  end

  private

  attr_reader :classroom, :date

  def school_day?(calendar)
    # [nil] quando a turma não tem série: valida só por eventos/etapas (mesmo sentinela do validador).
    grade_ids = classroom.grades.pluck(:id).presence || [nil]
    grade_ids.all? { |grade_id| calendar.day_allows_entry?(date, grade_id, classroom.id) }
  end
end
