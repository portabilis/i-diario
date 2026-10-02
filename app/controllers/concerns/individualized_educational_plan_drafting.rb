# Salvamento de rascunho do PEI: grava o plano sem publicar versão e responde em JSON, porque quem
# chama é o formulário via AJAX, que continua na tela. Nada aqui redireciona: o navegador seguiria
# o redirect e o JS receberia a página de destino no lugar da resposta.
#
# Incluir depois de IndividualizedEducationalPlanScoping: o handler de plano não encontrado
# daqui delega ao de lá com super.
module IndividualizedEducationalPlanDrafting
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :draft_aware_not_authorized
  end

  private

  def draft_request?
    params[:draft].present?
  end

  def create_draft
    existing = accessible_plan_for_student(@individualized_educational_plan.student_id)
    return render_draft_existing(existing) if existing

    unless student_permitted_for_creation?
      return render_draft_error(t('individualized_educational_plans.create.student_not_permitted'))
    end

    # Sem versão publicada não há autoria da turma: o rascunho de um aluno que não cursa mais a
    # turma ficaria fora de accessible_plans, sem como ser reaberto. Esse PEI só é gravado na
    # finalização, que publica a versão no mesmo envio.
    return render_draft_unavailable unless plan_editable?(@individualized_educational_plan)

    save_draft
  end

  def update_draft
    return unless assign_draft_attributes

    authorize_teacher_component_scope!
    save_draft
  end

  # Uma linha reenviada pode ter sido removida por outro usuário desde a carga da tela: a
  # atribuição levanta RecordNotFound, que o handler do controller responderia como plano não
  # encontrado.
  def assign_draft_attributes
    @individualized_educational_plan.assign_attributes(update_resource_params)
    true
  rescue ActiveRecord::RecordNotFound
    render_draft_error(t('individualized_educational_plans.draft.stale_record'), status: :conflict)
    false
  end

  def save_draft
    plan = @individualized_educational_plan
    return render_draft_saved if elaboration_day_valid? && plan.save_draft

    render_draft_error(plan.errors.full_messages)
  rescue ActiveRecord::RecordNotUnique => e
    Honeybadger.notify(e, context: { plan_id: plan.id, student_id: plan.student_id })
    render_draft_error(t('individualized_educational_plans.draft.conflict'))
  end

  # Devolve o formulário do plano recarregado do banco: é dele que a tela tira os registros
  # filhos já com id, o que impede o salvamento seguinte de criá-los de novo.
  def render_draft_saved
    @individualized_educational_plan = plan_with_components(@individualized_educational_plan.id)
    assign_display_fields
    build_default_review_dates
    set_form_options

    # .to_json (String) evita o wrapping com raiz do active_model_serializers no render json:.
    render json: draft_saved_payload(@individualized_educational_plan).to_json
  end

  def draft_saved_payload(plan)
    {
      id: plan.id,
      update_url: individualized_educational_plan_path(plan),
      edit_url: edit_individualized_educational_plan_path(plan),
      form_html: render_to_string(partial: 'form', formats: [:html])
    }
  end

  def render_draft_error(messages, status: :unprocessable_entity, **extra)
    render json: { errors: Array(messages) }.merge(extra).to_json, status: status
  end

  def render_draft_existing(plan)
    render_draft_error(
      t('individualized_educational_plans.draft.already_exists'),
      existing_plan_url: edit_individualized_educational_plan_path(plan)
    )
  end

  def render_draft_unavailable
    render_draft_error(t('individualized_educational_plans.draft.unavailable'), draft_unavailable: true)
  end

  def render_draft_read_only
    render_draft_error(t('individualized_educational_plans.flash.read_only_transferred'), status: :forbidden)
  end

  def individualized_educational_plan_not_found
    return super unless draft_request?

    render_draft_error(t('individualized_educational_plans.flash.not_found'), status: :not_found)
  end

  def draft_aware_not_authorized(exception)
    return user_not_authorized(exception) unless draft_request?

    render_draft_error(t('individualized_educational_plans.draft.not_authorized'), status: :forbidden)
  end
end
