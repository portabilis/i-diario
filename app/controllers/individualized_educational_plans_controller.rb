class IndividualizedEducationalPlansController < ApplicationController
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
    authorize IndividualizedEducationalPlan, :new?

    # find no escopo dos alunos permitidos: aluno de outra turma/escola resulta em 404,
    # não vaza nascimento/diagnóstico/responsáveis via ?student_id sequencial.
    student = permitted_students.find(params[:student_id])

    data = IndividualizedEducationalPlanPrefill.student_data(student, classroom: current_user_classroom)
    data[:has_existing_plan] = existing_plan?(student.id)

    render json: data
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def new
    teacher = regent_teacher

    @individualized_educational_plan = IndividualizedEducationalPlan.new(
      unity_id: current_unity&.id,
      classroom_id: current_user_classroom&.id,
      teacher_id: teacher&.id,
      year: current_school_year,
      elaborated_at: Date.current,
      unity_name: current_unity&.name,
      classroom_name: current_user_classroom&.description,
      teacher_name: teacher&.name
    )
    build_default_review_dates
    set_form_options

    authorize @individualized_educational_plan
  end

  def create
    @individualized_educational_plan = IndividualizedEducationalPlan.new(create_resource_params)

    authorize @individualized_educational_plan

    if @individualized_educational_plan.save
      respond_with @individualized_educational_plan, location: individualized_educational_plans_path
    else
      assign_display_fields
      set_form_options
      render :new
    end
  end

  def edit
    @individualized_educational_plan = IndividualizedEducationalPlan.includes(
      iep_curricular_plannings: [:discipline, :knowledge_area, { iep_curricular_planning_options: :iep_option }],
      iep_periodic_evaluations: [:discipline, :knowledge_area]
    ).find(params[:id])
    assign_display_fields
    # Mantém 3 campos de data de revisão na edição, completando com campos vazios
    # quando o plano foi salvo com menos de 3 (as datas já preenchidas são preservadas).
    build_default_review_dates
    set_form_options

    authorize @individualized_educational_plan
  end

  def update
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])
    @individualized_educational_plan.assign_attributes(update_resource_params)

    authorize @individualized_educational_plan

    if @individualized_educational_plan.save
      respond_with @individualized_educational_plan, location: individualized_educational_plans_path
    else
      assign_display_fields
      set_form_options
      render :edit
    end
  end

  def destroy
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])

    authorize @individualized_educational_plan

    @individualized_educational_plan.destroy

    respond_with @individualized_educational_plan, location: individualized_educational_plans_path
  end

  private

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

  # Criar por padrão 3 campos de data de revisão.
  def build_default_review_dates
    (3 - @individualized_educational_plan.iep_review_dates.size).times do
      @individualized_educational_plan.iep_review_dates.build
    end
  end

  def set_form_options
    @students = permitted_students.order(:name)
    @aee_teachers = current_unity ? Teacher.by_unity_id(current_unity.id).order_by_name : Teacher.none
    @iep_options_by_kind = IepOption.enabled.ordered.group_by(&:kind)
    @disciplines = Discipline.by_classroom_id(@classrooms.map(&:id)).ordered
    @knowledge_areas = KnowledgeArea.by_classroom_id(@classrooms.map(&:id)).ordered
  end

  # Alunos que o usuário pode selecionar no PEI: enturmados nas turmas do seu perfil.
  def permitted_students
    set_options_by_user
    student_ids = StudentEnrollment.by_classroom(@classrooms.map(&:id)).active.select(:student_id)
    Student.where(id: student_ids)
  end

  def create_resource_params
    params.require(:individualized_educational_plan).permit(:student_id).merge(resource_params)
  end

  def update_resource_params
    resource_params
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
      iep_curricular_plannings_attributes: [
        :id, :discipline_id, :knowledge_area_id, :iep_review_date_id,
        :long_term_goal, :stage_objectives, :skills_to_develop, :methodologies, :_destroy,
        :instructional_accommodation_option_ids, :environmental_accommodation_option_ids,
        :assessment_accommodation_option_ids,
        { instructional_accommodation_option_ids: [], environmental_accommodation_option_ids: [],
          assessment_accommodation_option_ids: [] }
      ],
      iep_periodic_evaluations_attributes: [
        :id, :discipline_id, :knowledge_area_id, :iep_review_date_id,
        :acquired_skills, :in_progress_skills, :not_acquired_skills, :period_report,
        :next_stage_adjustments, :_destroy
      ]
    )
  end

  # `||=` (não trocar por `=`): preserva o filtro limpo pelo professor (`by_classroom_id: ''`),
  # que o `has_scope` ignora por ser blank, caindo para todas as turmas dele.
  def set_filters
    params[:filter] ||= {}
    params[:filter][:by_classroom_id] ||= current_user_classroom.id
  end

  # Admin/servidor: turma selecionada no perfil.
  # Professor: todas as turmas que leciona na escola selecionada no perfil, no ano.
  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      fetch_classrooms
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_classrooms
    @classrooms ||= [current_user_classroom].compact
  end

  def fetch_linked_by_teacher
    fetched = TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms = fetched ? fetched[:classrooms] : []
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
