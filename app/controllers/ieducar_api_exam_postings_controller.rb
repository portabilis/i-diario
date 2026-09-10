class IeducarApiExamPostingsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_current_teacher_discipline_classrooms
  before_action :require_current_posting_step

  def index
    steps
  end

  def create
    authorize(IeducarApiExamPosting.new)

    posting_attributes = permitted_attributes.to_h.merge(
      author: current_user,
      teacher: current_user.current_teacher,
      ieducar_api_configuration: IeducarApiConfiguration.current,
      automatic: false
    )

    IeducarExamPostingLauncher.call(
      attributes: posting_attributes,
      entity_id: current_entity.id,
      force_posting: params[:force_posting]
    )

    redirect_to ieducar_api_exam_postings_path
  end

  def done_percentage
    posting = IeducarApiExamPosting.find(params[:id])

    render json: { percentage: posting.done_percentage }
  end

  private

  def permitted_attributes
    params.permit(
      :school_calendar_step_id,
      :school_calendar_classroom_step_id,
      :post_type
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def steps
    @steps = steps_fetcher.steps
    @steps = @steps.posting_date_after_and_before(Time.zone.today) unless posting_without_restrictions?

    @steps.each do |step|
      ApiPostingTypes.each_value do |value|
        # O envio automático não tem autor, então o filtro por author_id já o excluiria; o .manual
        # mantém a tela correta caso o envio automático passe a registrar um autor.
        ieducar_api_exam_posting = IeducarApiExamPosting.manual
                                                        .where(step_column => step.id, author_id: current_user.id)
                                                        .send(value)
                                                        .last

        instance_variable_set("@step_#{step.id}_#{value}_posting", ieducar_api_exam_posting)
      end
    end
  end

  def step_column
    @step_column ||= steps_fetcher.step_type == StepTypes::CLASSROOM ? :school_calendar_classroom_step_id : :school_calendar_step_id
  end
  helper_method :step_column

  # As faltas da última etapa fecham a situação final do aluno no i-Educar, então só essa
  # linha pede confirmação antes do envio.
  def last_step_absence_warning?(step, post_type)
    post_type == ApiPostingTypes::ABSENCE && step.id == last_step_by_year&.id
  end
  helper_method :last_step_absence_warning?

  def last_step_by_year
    return @last_step_by_year if defined?(@last_step_by_year)

    @last_step_by_year = steps_fetcher.last_step_by_year
  end
  helper_method :last_step_by_year

  # A liberação da tela consulta as mesmas etapas da listagem: turma com calendário próprio tem as
  # próprias janelas de lançamento, que substituem integralmente as da unidade.
  def require_current_posting_step
    return unless current_school_calendar
    return if posting_without_restrictions?
    return if steps_fetcher.steps.posting_date_after_and_before(Time.zone.today).exists?

    flash[:alert] = t('errors.ieducar_api_exam_postings.require_current_posting_step')

    redirect_to root_path
  end

  def posting_without_restrictions?
    current_user.can_change?(Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS)
  end

  def require_current_teacher_discipline_classrooms
    return if current_teacher&.teacher_discipline_classrooms&.any?

    flash[:alert] = t('errors.general.require_current_teacher_discipline_classrooms')

    redirect_to root_path
  end
end
