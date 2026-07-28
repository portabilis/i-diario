class IndividualizedEducationalPlansController < ApplicationController
  include RendersIepPdf
  include IndividualizedEducationalPlanScoping

  # Quantidade de campos de data de revisão exibidos por padrão no formulário.
  DEFAULT_REVIEW_DATES_COUNT = 3

  # Atributos permitidos das seções 4/5 (planejamento/avaliação), compartilhados entre o params
  # completo (admin/servidor) e o restrito do professor — para não divergirem em silêncio.
  CURRICULAR_PLANNING_ATTRIBUTES = [
    :id, :discipline_id, :knowledge_area_id, :iep_review_date_id,
    :long_term_goal, :stage_objectives, :skills_to_develop, :methodologies, :_destroy,
    :instructional_accommodation_option_ids, :environmental_accommodation_option_ids,
    :assessment_accommodation_option_ids,
    { instructional_accommodation_option_ids: [], environmental_accommodation_option_ids: [],
      assessment_accommodation_option_ids: [] }
  ].freeze

  PERIODIC_EVALUATION_ATTRIBUTES = [
    :id, :discipline_id, :knowledge_area_id, :iep_review_date_id,
    :acquired_skills, :in_progress_skills, :not_acquired_skills, :period_report,
    :next_stage_adjustments, :_destroy
  ].freeze

  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_classroom

  def index
    set_options_by_user
    set_filters

    @individualized_educational_plans = fetch_plans

    authorize @individualized_educational_plans
  end

  # Alimenta o filtro de aluno em cascata: só alunos que têm PEI na turma selecionada.
  def fetch_students_by_classroom
    authorize IndividualizedEducationalPlan, :index?

    return render(json: [].to_json) if params[:classroom_id].blank?

    student_ids = IndividualizedEducationalPlan.by_classroom_id(params[:classroom_id]).select(:student_id)
    students = Student.where(id: student_ids).order(:name).pluck(:id, :name)

    render json: students.map { |id, name| { id: id, name: name } }.to_json
  end

  # Prefill da seção 1: dados de identificação do aluno (nascimento, diagnóstico, responsáveis, turno)
  # + aviso antecipado de que o aluno já possui um PEI no ano letivo (antes de o usuário preencher).
  def student_data
    # Só :show? num plano existente (vem plan_id, o usuário só visualiza); :new? ao criar um PEI.
    authorize IndividualizedEducationalPlan, (params[:plan_id].present? ? :show? : :new?)

    student = student_for_data

    data = IndividualizedEducationalPlanPrefill.student_data(student, classroom: classroom_for_data)
    data[:has_existing_plan] = existing_plan?(student.id)

    render json: data
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error(
      "PEI: student_data não encontrou aluno — student_id=#{params[:student_id]} plan_id=#{params[:plan_id]}"
    )
    head :not_found
  end

  def show
    @individualized_educational_plan = plan_with_components
    authorize @individualized_educational_plan

    respond_to do |format|
      # HTML: mesmo formulário do preenchimento, em modo leitura.
      format.html do
        assign_display_fields
        set_form_options
      end
      # PDF: documento de impressão (flat), a partir do snapshot do plano vivo.
      format.pdf do
        @presenter = IndividualizedEducationalPlanReportPresenter.from_record(@individualized_educational_plan)
        send_iep_pdf(
          filename: "plano_educacional_individualizado_#{@individualized_educational_plan.id}.pdf",
          log_context: "plan #{@individualized_educational_plan.id}"
        )
      end
    end
  end

  def new
    teacher = regent_teacher

    @individualized_educational_plan = IndividualizedEducationalPlan.new(
      unity_id: current_unity&.id,
      classroom_id: current_user_classroom&.id,
      teacher_id: teacher&.id,
      year: current_school_year,
      elaborated_at: Date.current
    )
    authorize @individualized_educational_plan

    # Deriva unity_name/classroom_name/teacher_name dos *_id recém-atribuídos (mesma lógica
    # da re-renderização); no new não há aluno, então o prefill é no-op.
    assign_display_fields
    build_default_review_dates
    set_form_options
  end

  def create
    @individualized_educational_plan = IndividualizedEducationalPlan.new(create_resource_params)

    authorize @individualized_educational_plan

    if save_and_publish
      respond_after_save
    else
      render_form(:new)
    end
  end

  def edit
    @individualized_educational_plan = plan_with_components
    authorize @individualized_educational_plan

    assign_display_fields
    build_default_review_dates
    set_form_options
  end

  def update
    @individualized_educational_plan = plan_with_components
    @individualized_educational_plan.assign_attributes(update_resource_params)

    authorize @individualized_educational_plan
    authorize_teacher_component_scope!

    if save_and_publish
      respond_after_save
    else
      render_form(:edit)
    end
  end

  def destroy
    # Escopado por turma (accessible_plans): impede excluir plano de turma sem vínculo — a policy
    # só valida a feature + perfil, não o registro. Sem isto, exclusão destrutiva por id (IDOR).
    @individualized_educational_plan = accessible_plans.find(params[:id])

    authorize @individualized_educational_plan

    @individualized_educational_plan.destroy

    respond_with @individualized_educational_plan, location: individualized_educational_plans_path
  end

  private

  # Salva o plano e publica uma versão na mesma transação. version_name é obrigatório:
  # sem ele, registra erro e retorna false para re-renderizar o formulário.
  def save_and_publish
    if version_name.blank?
      @individualized_educational_plan.errors.add(:base, t('individualized_educational_plans.finalize.version_name_required'))
      return false
    end

    # Busca externa (i-Educar, até 240s) fora da transação: dentro dela prenderia a conexão presa.
    prefetched_student_data = student_data_for_snapshot

    ActiveRecord::Base.transaction do
      saved = @individualized_educational_plan.save
      raise ActiveRecord::Rollback unless saved

      authorize @individualized_educational_plan, :finalize?
      IndividualizedEducationalPlanPublisher.publish!(
        @individualized_educational_plan, name: version_name, published_by: current_user,
        student_data: prefetched_student_data
      )

      saved
    end
  rescue ActiveRecord::RecordNotUnique
    @individualized_educational_plan.errors.add(:base, t('individualized_educational_plans.finalize.already_published'))
    false
  end

  def respond_after_save
    redirect_to individualized_educational_plans_path,
                notice: t('individualized_educational_plans.finalize.success')
  end

  def version_name
    params[:version_name].to_s.strip
  end

  def student_data_for_snapshot
    return unless version_name.present?
    return if @individualized_educational_plan.student.blank?

    IndividualizedEducationalPlanPrefill.student_data(
      @individualized_educational_plan.student,
      classroom: @individualized_educational_plan.classroom
    )
  end

  # Repopula os campos de exibição e opções e re-renderiza o formulário (após erro de validação).
  def render_form(action)
    assign_display_fields
    set_form_options
    render action
  end

  # Plano restrito às turmas do usuário (accessible_plans), com as seções 4/5 e suas opções
  # pré-carregadas para a tela e para o escopo do professor.
  def plan_with_components
    accessible_plans.includes(
      iep_curricular_plannings: [:discipline, :knowledge_area, :iep_review_date,
                                 { iep_curricular_planning_options: :iep_option }],
      iep_periodic_evaluations: [:discipline, :knowledge_area, :iep_review_date]
    ).find(params[:id])
  end

  # Professor da seção 1 = regente da turma (ref_cod_regente do i-Educar, sincronizado
  # em classrooms.regent_api_code). Sem regente cadastrado, retorna nil (o formulário
  # exibe o aviso e o PEI pode ser criado sem professor responsável).
  def regent_teacher
    Teacher.find_by(api_code: current_user_classroom&.regent_api_code)
  end

  # Recarrega os dados de exibição do formulário para evitar campos readonly em branco
  # após re-renderização (edição, erro de validação ou remoção).
  def assign_display_fields
    plan = @individualized_educational_plan
    plan.unity_name = plan.unity&.name
    plan.classroom_name = plan.classroom&.description
    plan.teacher_name = plan.teacher&.name
    prefill_student_fields
  end

  def existing_plan?(student_id)
    scope = IndividualizedEducationalPlan.where(student_id: student_id, year: current_school_year)
    scope = scope.where.not(id: params[:plan_id]) if params[:plan_id].present?
    scope.exists?
  end

  # Dados locais (sem chamada externa) para exibir de imediato no formulário.
  # "Responsáveis" não é preenchido aqui — depende de chamada síncrona ao i-Educar
  # sem timeout curto disponível; é buscado via AJAX no carregamento da página
  # (form.js dispara o mesmo fetch do endpoint student_data quando há aluno selecionado).
  def prefill_student_fields
    return if @individualized_educational_plan.student.blank?

    data = IndividualizedEducationalPlanPrefill.local_student_data(
      @individualized_educational_plan.student,
      classroom: @individualized_educational_plan.classroom
    )
    @individualized_educational_plan.birth_date = data[:birth_date]
    @individualized_educational_plan.diagnosis = data[:diagnosis]
    @individualized_educational_plan.shift = data[:shift]
  end

  # Completa os campos de data de revisão até o padrão (as já preenchidas são preservadas).
  def build_default_review_dates
    (DEFAULT_REVIEW_DATES_COUNT - @individualized_educational_plan.iep_review_dates.size).times do
      @individualized_educational_plan.iep_review_dates.build
    end
  end

  def set_form_options
    @students = form_students.order(:name)
    @aee_teachers = current_unity ? Teacher.by_unity_id(current_unity.id).order_by_name : Teacher.none
    @iep_options_by_kind = IepOption.enabled.ordered.group_by(&:kind)
    set_component_options
  end

  # Componentes das seções 4/5. Cada ramo parte de uma turma diferente: o admin/servidor
  # lista os da turma do perfil (current_user_classroom); o professor, só os que leciona na
  # turma do PLANO (via teacher_component_permission). @editable_component_scope tem duplo papel na view:
  # sua mera presença coloca as seções 1-3 e 6 em leitura (sections_read_only no _form) e ele
  # decide quais linhas das seções 4/5 são editáveis. nil (admin/servidor) = tudo editável.
  def set_component_options
    if admin_or_employee?
      classroom_ids = [current_user_classroom&.id].compact
      @editable_component_scope = nil
      @disciplines = Discipline.by_classroom_id(classroom_ids).ordered
      @knowledge_areas = KnowledgeArea.by_classroom_id(classroom_ids).ordered
    else
      @editable_component_scope = teacher_component_permission
      @disciplines = teacher_component_permission.disciplines
      @knowledge_areas = teacher_component_permission.knowledge_areas
    end
  end

  def form_students
    return Student.where(id: @individualized_educational_plan.student_id) if @individualized_educational_plan.persisted?

    permitted_students
  end

  # Alunos que o usuário pode selecionar ao criar um PEI: só os enturmados na turma do PERFIL
  # selecionado (não em todas as turmas que o professor leciona — diferente da listagem).
  def permitted_students
    return Student.none if current_user_classroom.blank?

    student_ids = StudentEnrollment.by_classroom(current_user_classroom.id).active.select(:student_id)
    Student.where(id: student_ids)
  end

  def student_for_data
    if data_plan
      return data_plan.student if data_plan.student_id.to_s == params[:student_id].to_s
    end

    permitted_students.find(params[:student_id])
  end

  def data_plan
    return @data_plan if defined?(@data_plan)

    @data_plan = params[:plan_id].present? ? IndividualizedEducationalPlan.find(params[:plan_id]) : nil
  end

  def classroom_for_data
    data_plan&.classroom || current_user_classroom
  end

  def create_resource_params
    params.require(:individualized_educational_plan).permit(:student_id).merge(resource_params)
  end

  # Admin/servidor editam o PEI inteiro; o professor só as seções 4/5 (planejamento/avaliação).
  def update_resource_params
    return resource_params if admin_or_employee?

    teacher_resource_params
  end

  # Permite ao professor apenas as linhas das seções 4/5 (planejamento e avaliação); as demais
  # seções são descartadas pelo strong parameters.
  def teacher_resource_params
    params.require(:individualized_educational_plan).permit(
      iep_curricular_plannings_attributes: CURRICULAR_PLANNING_ATTRIBUTES,
      iep_periodic_evaluations_attributes: PERIODIC_EVALUATION_ATTRIBUTES
    )
  end

  # Trava server-side do professor: nenhuma linha das seções 4/5 alterada neste submit pode
  # ser de outro componente (nem por reatribuição de linha existente). Admin/servidor passam.
  def authorize_teacher_component_scope!
    return if admin_or_employee?
    return if teacher_component_permission.touched_lines_authorized?

    Rails.logger.error(
      "PEI: professor tentou editar componente fora do escopo — plan=#{@individualized_educational_plan.id} " \
      "teacher=#{current_teacher&.id} user=#{current_user&.id}"
    )
    raise Pundit::NotAuthorizedError.new(query: :update?, record: @individualized_educational_plan)
  end

  def teacher_component_permission
    @teacher_component_permission ||=
      IndividualizedEducationalPlanTeacherComponentPermission.new(current_teacher, @individualized_educational_plan)
  end

  def admin_or_employee?
    current_user.current_role_is_admin_or_employee?
  end

  def resource_params
    params.require(:individualized_educational_plan).permit(
      :unity_id, :classroom_id, :teacher_id, :aee_teacher_id, :year,
      :support_professional, :elaborated_at,
      :characterization, :clinical_diagnosis_justification, :school_history,
      :potentialities, :difficulties, :preferences_interests, :effective_strategies,
      :family_guidelines, :external_professionals_guidelines,
      :annual_report, :overall_evolution, :next_year_recommendations, :referrals_made,
      :communication_profile_option_ids, :social_interaction_profile_option_ids,
      :autonomy_option_ids, :accompaniment_option_ids, :support_type_option_ids,
      communication_profile_option_ids: [], social_interaction_profile_option_ids: [],
      autonomy_option_ids: [], accompaniment_option_ids: [], support_type_option_ids: [],
      iep_review_dates_attributes: [:id, :review_date, :_destroy],
      iep_attachments_attributes: [:id, :attachment, :attachment_cache, :_destroy],
      iep_curricular_plannings_attributes: CURRICULAR_PLANNING_ATTRIBUTES,
      iep_periodic_evaluations_attributes: PERIODIC_EVALUATION_ATTRIBUTES
    )
  end

  # `||=` (não trocar por `=`): preserva o filtro limpo pelo professor (`by_classroom_id: ''`),
  # que o `has_scope` ignora por ser blank, caindo para todas as turmas dele.
  def set_filters
    params[:filter] ||= {}
    params[:filter][:by_classroom_id] ||= current_user_classroom.id
  end

  # Turmas do usuário para os filtros/listagem do índice (mesmo escopo de accessible_classrooms).
  def set_options_by_user
    @classrooms = accessible_classrooms
  end

  def fetch_plans
    apply_scopes(
      IndividualizedEducationalPlan
        .by_classroom_id(@classrooms.map(&:id))
        .includes(:student, :classroom, :unity)
        .order(updated_at: :desc)
    )
  end
end
