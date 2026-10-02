class IndividualizedEducationalPlansController < ApplicationController
  include RendersIepPdf
  include IndividualizedEducationalPlanScoping
  include IndividualizedEducationalPlanDrafting

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
    index_classrooms = IndividualizedEducationalPlanIndexClassroomsQuery.new(
      @individualized_educational_plans, accessible_classroom_ids
    )
    @display_classrooms = index_classrooms.display_classrooms
    @editable_student_ids = index_classrooms.editable_student_ids

    authorize @individualized_educational_plans
  end

  # Alimenta o filtro de aluno em cascata: só alunos que têm PEI na turma selecionada.
  def fetch_students_by_classroom
    authorize IndividualizedEducationalPlan, :index?

    # .to_json (String) evita o wrapping com raiz do active_model_serializers no render json:.
    return render(json: [].to_json) if params[:classroom_id].blank?
    # Só turma do usuário: sem isto, um classroom_id forjado listaria alunos de turma alheia.
    return render(json: [].to_json) unless accessible_classroom_ids.include?(params[:classroom_id].to_i)

    # Escopado ao ano letivo, como o accessible_plans que alimenta a listagem: sem isto, um aluno
    # cujo único PEI na turma é de ano anterior vira opção do dropdown que resulta em lista vazia.
    student_ids = IndividualizedEducationalPlan.kept
                                               .where(year: current_school_year)
                                               .by_classroom_id(params[:classroom_id])
                                               .select(:student_id)
    students = Student.where(id: student_ids).order(:name).pluck(:id, :name)

    render json: students.map { |id, name| { id: id, name: name } }.to_json
  end

  def students_by_elaboration_date
    authorize IndividualizedEducationalPlan, :new?

    date = parsed_elaboration_date
    students = permitted_students(date).order(:name).pluck(:id, :name).map { |id, name| { id: id, name: name } }

    render json: {
      students: students,
      calendar_error: IndividualizedEducationalPlanElaborationDayCheck.error_for(
        current_user_classroom, date, year: current_school_year
      )
    }.to_json
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  # Prefill da seção 1: dados de identificação do aluno (nascimento, diagnóstico, responsáveis, turno)
  # + aviso antecipado de que o aluno já possui um PEI no ano letivo (antes de o usuário preencher).
  def student_data
    authorize_student_query
    # Prefill traz dados VIVOS do aluno (nascimento, diagnóstico, responsáveis). Autor que não
    # cursa mais o aluno vê o plano congelado — não deve puxar o estado atual por este endpoint.
    return head :forbidden if frozen_plan_for_data?

    student = student_for_data

    data = IndividualizedEducationalPlanPrefill.student_data(student, classroom: classroom_for_data)
    data[:has_existing_plan] = plan_exists_for_student?(student.id)

    render json: data
  rescue ActiveRecord::RecordNotFound
    student_query_not_found(:student_data)
  end

  # Laudos do aluno: a fonte é o cadastro do aluno no i-Educar — o i-Diário não guarda cópia.
  # Endpoint próprio (e não só dentro do student_data) porque a tela de versão publicada não
  # busca o restante dos dados, congelados no snapshot, mas o laudo é sempre o atual.
  def medical_reports
    authorize_student_query

    render json: IndividualizedEducationalPlanPrefill.medical_reports_data(student_for_medical_reports)
  rescue ActiveRecord::RecordNotFound
    student_query_not_found(:medical_reports)
  end

  # Abre o laudo. A URL que o i-Educar devolve é assinada e expira em 5 minutos, então é
  # resolvida aqui, no clique, em vez de ser renderizada na tela e usada depois.
  def open_medical_report
    authorize_student_query

    lookup = IndividualizedEducationalPlanPrefill.medical_report_lookup(
      student_for_medical_reports, params[:name], params[:created_at]
    )

    # O link abre em outra aba: resposta vazia viraria uma aba em branco, sem dizer o motivo.
    return redirect_to_plans(:medical_report_unavailable) if lookup[:unavailable]
    return redirect_to_plans(:medical_report_gone) if lookup[:url].blank?

    redirect_to lookup[:url]
  rescue ActiveRecord::RecordNotFound
    student_query_not_found(:open_medical_report)
  end

  def upload_medical_report
    authorize IndividualizedEducationalPlan, (params[:plan_id].present? ? :update? : :new?)

    return render_upload_error(upload_t(:not_allowed), :forbidden) unless admin_or_employee?

    if medical_reports_plan && !plan_editable?(medical_reports_plan)
      return render_upload_error(t('individualized_educational_plans.flash.read_only_transferred'), :forbidden)
    end

    student = student_for_medical_reports

    if student.api_code.blank?
      return render_upload_error(upload_t(:student_without_ieducar), :unprocessable_entity)
    end

    result = IeducarApi::MedicalReports.upload(student_api_code: student.api_code, file: params[:file])

    render json: { message: result.message }, status: (result.success? ? :ok : result.http_status)
  rescue ActiveRecord::RecordNotFound
    student_query_not_found(:upload_medical_report)
  end

  def show
    @individualized_educational_plan = plan_with_components
    authorize @individualized_educational_plan
    @plan_editable = plan_editable?(@individualized_educational_plan)

    frozen = frozen_version_for(@individualized_educational_plan)
    if frozen
      return redirect_to individualized_educational_plan_version_path(
        @individualized_educational_plan, frozen, format: (:pdf if request.format.pdf?)
      )
    elsif !@plan_editable
      # Inativo sem versão do seu período: a visibilidade já barra este caso — defesa em
      # profundidade para nunca renderizar o plano vivo a quem não cursa mais o aluno.
      return individualized_educational_plan_not_found
    end

    respond_to do |format|
      # HTML: mesmo formulário do preenchimento, em modo leitura.
      format.html do
        assign_display_fields
        set_form_options
      end
      # PDF: documento de impressão (flat), a partir do snapshot do plano vivo.
      format.pdf do
        @presenter = IndividualizedEducationalPlanReportPresenter.from_record(
          @individualized_educational_plan, classroom: current_classroom_for(@individualized_educational_plan)
        )
        send_iep_pdf(
          filename: "plano_educacional_individualizado_#{@individualized_educational_plan.id}.pdf",
          log_context: "plan #{@individualized_educational_plan.id}"
        )
      end
    end
  end

  def new
    @individualized_educational_plan = IndividualizedEducationalPlan.new(
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

    return create_draft if draft_request?

    existing = accessible_plan_for_student(@individualized_educational_plan.student_id)
    return redirect_to_existing_plan(existing) if existing

    unless student_permitted_for_creation?
      @individualized_educational_plan.errors.add(
        :student_id, t('individualized_educational_plans.create.student_not_permitted')
      )
      return render_form(:new)
    end

    if save_and_publish
      respond_after_save
    else
      render_form(:new)
    end
  end

  def edit
    @individualized_educational_plan = plan_with_components
    authorize @individualized_educational_plan
    # Aluno transferido (sem enturmação aberta): edição não se aplica — cai na visualização (leitura),
    # com mensagem, em vez de um redirect calado. Editar é só para quem cursa o aluno.
    return read_only_transferred_redirect unless plan_editable?(@individualized_educational_plan)

    assign_display_fields
    build_default_review_dates
    set_form_options
  end

  def update
    @individualized_educational_plan = plan_with_components
    authorize @individualized_educational_plan
    unless plan_editable?(@individualized_educational_plan)
      return draft_request? ? render_draft_read_only : read_only_transferred_redirect
    end

    @individualized_educational_plan.assign_attributes(update_resource_params)

    authorize_teacher_component_scope!

    return save_draft if draft_request?

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

    return read_only_transferred_redirect unless plan_editable?(@individualized_educational_plan)

    # Arquiva em vez de apagar: o cascade não roda e as versões publicadas ficam preservadas.
    # discard grava com validação e devolve falsey de duas formas — false quando a validação
    # reprova e nil quando o plano já está arquivado. Sem tratar, a tela redirecionaria
    # anunciando uma exclusão que não aconteceu.
    unless @individualized_educational_plan.discarded? || @individualized_educational_plan.discard
      return archiving_failed(@individualized_educational_plan)
    end

    redirect_to individualized_educational_plans_path,
                notice: t('individualized_educational_plans.flash.archived')
  end

  private

  # Falha de arquivamento é sempre de validação, portanto determinística: repetir dá no mesmo, e a
  # mensagem precisa carregar o motivo. O plano em memória fica com discarded_at preenchido mesmo
  # sem ter gravado, então nada além dos errors deve ser lido dele daqui em diante.
  def archiving_failed(plan)
    reasons = plan.errors.full_messages.to_sentence
    Rails.logger.error("PEI: falha ao arquivar o plano #{plan.id}: #{reasons}")
    Honeybadger.notify('PEI archiving failed', context: { plan_id: plan.id, reasons: reasons })

    redirect_to individualized_educational_plans_path,
                alert: t('individualized_educational_plans.flash.archive_failed', reasons: reasons)
  end

  # Salva o plano e publica uma versão na mesma transação. version_name é obrigatório:
  # sem ele, registra erro e retorna false para re-renderizar o formulário.
  def save_and_publish
    if version_name.blank?
      @individualized_educational_plan.errors.add(:base, t('individualized_educational_plans.finalize.version_name_required'))
      return false
    end

    return false unless elaboration_day_valid?

    # Busca externa (i-Educar, até 240s) fora da transação: dentro dela prenderia a conexão presa.
    prefetched_student_data = student_data_for_snapshot

    ActiveRecord::Base.transaction do
      saved = @individualized_educational_plan.save
      raise ActiveRecord::Rollback unless saved

      authorize @individualized_educational_plan, :finalize?
      IndividualizedEducationalPlanPublisher.publish!(
        @individualized_educational_plan, name: version_name, published_by: current_user,
        student_data: prefetched_student_data,
        classroom: current_classroom_for(@individualized_educational_plan)
      )

      saved
    end
  rescue ActiveRecord::RecordNotUnique => e
    Honeybadger.notify(e, context: { plan_id: @individualized_educational_plan.id })
    @individualized_educational_plan.errors.add(:base, t('individualized_educational_plans.finalize.already_published'))
    false
  end

  # Só valida o dia letivo quando a data de elaboração é definida/alterada. No update ela é
  # readonly e não vem no submit do professor, então revalidar o valor armazenado (contra o
  # calendário da turma atual, possivelmente outra escola) trancaria a escola que recebeu o aluno.
  # O erro é registrado no plano: quem chama não pode salvar depois de um false, porque o save
  # revalida e limpa os erros.
  def elaboration_day_valid?
    plan = @individualized_educational_plan
    return true unless plan.new_record? || plan.elaborated_at_changed?

    calendar_error = IndividualizedEducationalPlanElaborationDayCheck.error_for(
      current_classroom_for(plan), plan.elaborated_at, year: plan.year
    )
    return true unless calendar_error

    plan.errors.add(:elaborated_at, calendar_error)
    false
  end

  def respond_after_save
    redirect_to individualized_educational_plans_path,
                notice: t('individualized_educational_plans.finalize.success')
  end

  # Aluno transferido (sem enturmação aberta na turma do usuário): o PEI é somente leitura.
  def read_only_transferred_redirect
    redirect_to individualized_educational_plan_path(@individualized_educational_plan),
                alert: t('individualized_educational_plans.flash.read_only_transferred')
  end

  def version_name
    params[:version_name].to_s.strip
  end

  def student_data_for_snapshot
    return unless version_name.present?
    return if @individualized_educational_plan.student.blank?

    IndividualizedEducationalPlanPrefill.student_data(
      @individualized_educational_plan.student,
      classroom: current_classroom_for(@individualized_educational_plan)
    )
  end

  # Repopula os campos de exibição e opções e re-renderiza o formulário (após erro de validação).
  def render_form(action)
    assign_display_fields
    set_form_options
    plan = @individualized_educational_plan
    # Plano novo que volta com aluno já escolhido e não cursando: o rascunho é recusado para ele
    # (ver create_draft), então o formulário abre com o salvamento automático desligado.
    @draft_unavailable = plan.new_record? && plan.student_id.present? && !plan_editable?(plan)
    render action
  end

  # Plano restrito às turmas do usuário (accessible_plans), com as seções 4/5 e suas opções
  # pré-carregadas para a tela e para o escopo do professor.
  def plan_with_components(id = params[:id])
    accessible_plans.includes(
      iep_curricular_plannings: [:discipline, :knowledge_area, :iep_review_date,
                                 { iep_curricular_planning_options: :iep_option }],
      iep_periodic_evaluations: [:discipline, :knowledge_area, :iep_review_date]
    ).find(id)
  end

  def current_classroom_for(plan)
    return current_user_classroom unless plan&.persisted?

    cache = (@current_classroom_for ||= {})
    return cache[plan.id] if cache.key?(plan.id)

    cache[plan.id] = begin
      attending_ids = StudentEnrollmentClassroom.attending_classroom_ids(
        accessible_classroom_ids, plan.student_id
      )

      # Aluno cursa a turma do perfil → mantém a do perfil.
      if attending_ids.include?(current_user_classroom&.id)
        current_user_classroom
      # Não cursa a do perfil (ex.: cursa B e C) → a de menor id entre as que cursa. O order fixa
      # a escolha para não gravar autorias diferentes em dois saves.
      else
        Classroom.where(id: attending_ids).order(:id).first || current_user_classroom
      end
    end
  end

  # Recarrega os dados de exibição do formulário (escola/turma/regente derivados da turma atual)
  # para evitar campos readonly em branco após re-renderização.
  def assign_display_fields
    plan = @individualized_educational_plan
    classroom = current_classroom_for(plan)
    plan.unity_name = classroom&.unity&.name
    plan.classroom_name = classroom&.description
    plan.teacher_name = classroom&.regent&.name
    prefill_student_fields
  end

  # Só entre os vivos: o retorno alimenta o aviso de "aluno já possui PEI" no formulário, que
  # ficaria obsoleto apontando um plano arquivado. Quem barra a criação em si é accessible_plans
  # com o índice único parcial, não este método.
  def plan_exists_for_student?(student_id)
    scope = IndividualizedEducationalPlan.kept.where(student_id: student_id, year: current_school_year)
    scope = scope.where.not(id: params[:plan_id]) if params[:plan_id].present?
    scope.exists?
  end

  def accessible_plan_for_student(student_id)
    return if student_id.blank?

    accessible_plans.find_by(student_id: student_id)
  end

  def redirect_to_existing_plan(plan)
    redirect_to edit_individualized_educational_plan_path(plan),
                notice: t('individualized_educational_plans.flash.already_exists_editing')
  end

  # Dados locais (sem chamada externa) para exibir de imediato no formulário.
  # "Responsáveis" não é preenchido aqui — depende de chamada síncrona ao i-Educar
  # sem timeout curto disponível; é buscado via AJAX no carregamento da página
  # (form.js dispara o mesmo fetch do endpoint student_data quando há aluno selecionado).
  def prefill_student_fields
    return if @individualized_educational_plan.student.blank?

    data = IndividualizedEducationalPlanPrefill.local_student_data(
      @individualized_educational_plan.student,
      classroom: current_classroom_for(@individualized_educational_plan)
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

    permitted_students(@individualized_educational_plan.elaborated_at || Date.current)
  end

  def student_permitted_for_creation?
    permitted_students(@individualized_educational_plan.elaborated_at || Date.current)
      .exists?(id: @individualized_educational_plan.student_id)
  end

  # Alunos selecionáveis ao criar um PEI: enturmados na turma do perfil NA DATA informada (matrícula
  # ativa). Usa by_date (não status "cursando hoje") para permitir PEI retroativo de aluno já transferido.
  def permitted_students(on_date = Date.current)
    return Student.none if current_user_classroom.blank?

    student_ids = StudentEnrollmentClassroom
                  .by_classroom(current_user_classroom.id)
                  .by_date(on_date)
                  .active
                  .joins(:student_enrollment)
                  .select('student_enrollments.student_id')
    Student.where(id: student_ids)
  end

  # Data de elaboração vinda do select via AJAX; inválida/ausente cai para hoje (registra o valor
  # rejeitado para não trocar a data em silêncio).
  def parsed_elaboration_date
    Date.parse(params[:elaborated_at].to_s)
  rescue ArgumentError
    if params[:elaborated_at].present?
      Rails.logger.warn("PEI: elaborated_at inválido (#{params[:elaborated_at].inspect}) — usando a data atual")
    end
    Date.current
  end

  def student_for_data
    if data_plan
      return data_plan.student if data_plan.student_id.to_s == params[:student_id].to_s
    end

    permitted_students(parsed_elaboration_date).find(params[:student_id])
  end

  def frozen_plan_for_data?
    plan = data_plan || accessible_plan_for_student(params[:student_id])

    plan.present? && !plan_editable?(plan)
  end

  # Escopado por accessible_plans: o plan_id vem do cliente e decide de qual aluno o prefill
  # devolve os dados, então sem escopo ele burla o permitted_students do caminho de baixo.
  def data_plan
    return @data_plan if defined?(@data_plan)

    @data_plan = params[:plan_id].present? ? accessible_plans.find(params[:plan_id]) : nil
  end

  def classroom_for_data
    data_plan ? current_classroom_for(data_plan) : current_user_classroom
  end

  # Consultas de dados do aluno (prefill e laudos): só :show? num plano existente (vem plan_id,
  # o usuário só visualiza); :new? ao criar um PEI.
  def authorize_student_query
    authorize IndividualizedEducationalPlan, (params[:plan_id].present? ? :show? : :new?)
  end

  def redirect_to_plans(flash_key)
    redirect_to individualized_educational_plans_path,
                alert: t("individualized_educational_plans.flash.#{flash_key}")
  end

  def render_upload_error(message, status)
    render json: { message: message }, status: status
  end

  def upload_t(key)
    t("individualized_educational_plans.medical_report_upload.#{key}")
  end

  def student_query_not_found(action)
    context = {
      action: action, student_id: params[:student_id], plan_id: params[:plan_id],
      elaborated_at: params[:elaborated_at]
    }
    Rails.logger.error("PEI: #{action} não encontrou aluno/plano — #{context}")
    Honeybadger.notify("PEI: consulta de aluno não encontrada", context: context)
    head :not_found
  end

  # Aluno da consulta de laudos: pelo plano (edição/visualização/versão, onde o aluno da tela
  # pode ser um stand-in do snapshot) ou pelo aluno escolhido no formulário (criação).
  def student_for_medical_reports
    return medical_reports_plan.student if medical_reports_plan

    permitted_students(parsed_elaboration_date).find(params[:student_id])
  end

  def medical_reports_plan
    return @medical_reports_plan if defined?(@medical_reports_plan)

    @medical_reports_plan = params[:plan_id].present? ? accessible_plans.find(params[:plan_id]) : nil
  end

  def create_resource_params
    params.require(:individualized_educational_plan)
          .permit(:student_id)
          .merge(resource_params)
          .merge(year: current_school_year)
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
      :aee_teacher_id,
      :support_professional, :elaborated_at,
      :characterization, :clinical_diagnosis_justification, :school_history,
      :potentialities, :difficulties, :preferences_interests, :effective_strategies,
      :family_guidelines, :external_professionals_guidelines,
      :uses_medication, :medication_notes, :family_environment_characteristics,
      :annual_report, :overall_evolution, :next_year_recommendations, :referrals_made,
      :communication_profile_option_ids, :social_interaction_profile_option_ids,
      :autonomy_option_ids, :accompaniment_option_ids, :support_type_option_ids,
      communication_profile_option_ids: [], social_interaction_profile_option_ids: [],
      autonomy_option_ids: [], accompaniment_option_ids: [], support_type_option_ids: [],
      iep_review_dates_attributes: [:id, :review_date, :_destroy],
      iep_medications_attributes: [:id, :name, :dosage, :schedule, :_destroy],
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
    apply_scopes(accessible_plans.includes(:student).order(updated_at: :desc))
  end
end
