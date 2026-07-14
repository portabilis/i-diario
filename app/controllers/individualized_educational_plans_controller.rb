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

    student_ids = IndividualizedEducationalPlan.by_classroom_id(params[:classroom_id]).select(:student_id)
    students = Student.where(id: student_ids).order(:name).pluck(:id, :name)

    render json: students.map { |id, name| { id: id, name: name } }.to_json
  end

  # Prefill da seção 1: dados de identificação do aluno (nascimento, diagnóstico, responsáveis).
  def student_data
    student = Student.find(params[:student_id])

    render json: IndividualizedEducationalPlanPrefill.student_data(
      student, unity: current_unity, year: current_school_year
    )
  end

  def new
    @individualized_educational_plan = IndividualizedEducationalPlan.new(
      unity_id: current_unity&.id,
      teacher_id: current_teacher&.id, # stopgap: regente virá do i-Educar (D20)
      year: current_school_year,
      elaborated_at: Date.current,
      unity_name: current_unity&.name,
      teacher_name: current_teacher&.name
    )
    build_default_review_dates
    set_form_options

    authorize @individualized_educational_plan
  end

  def create
    @individualized_educational_plan = IndividualizedEducationalPlan.new(resource_params)

    authorize @individualized_educational_plan

    if @individualized_educational_plan.save
      respond_with @individualized_educational_plan, location: individualized_educational_plans_path
    else
      set_form_options
      render :new
    end
  end

  def edit
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])
    @individualized_educational_plan.unity_name = @individualized_educational_plan.unity&.name
    @individualized_educational_plan.teacher_name = @individualized_educational_plan.teacher&.name
    set_form_options

    authorize @individualized_educational_plan
  end

  def update
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])
    @individualized_educational_plan.assign_attributes(resource_params)

    authorize @individualized_educational_plan

    if @individualized_educational_plan.save
      respond_with @individualized_educational_plan, location: individualized_educational_plans_path
    else
      set_form_options
      render :edit
    end
  end

  private

  # Criar por padrão 3 campos de data de revisão.
  def build_default_review_dates
    (3 - @individualized_educational_plan.iep_review_dates.size).times do
      @individualized_educational_plan.iep_review_dates.build
    end
  end

  def set_form_options
    set_options_by_user
    student_ids = StudentEnrollment.by_classroom(@classrooms.map(&:id)).active.select(:student_id)
    @students = Student.where(id: student_ids).order(:name)
    @aee_teachers = current_unity ? Teacher.by_unity_id(current_unity.id).order_by_name : Teacher.none
    @iep_options = IepOption.enabled.ordered
  end

  def resource_params
    params.require(:individualized_educational_plan).permit(
      :student_id, :unity_id, :classroom_id, :teacher_id, :aee_teacher_id, :year,
      :support_professional, :elaborated_at,
      :characterization, :clinical_diagnosis_justification, :school_history,
      :potentialities, :difficulties, :preferences_interests, :effective_strategies,
      :family_guidelines, :external_professionals_guidelines,
      :annual_report, :overall_evolution, :next_year_recommendations, :referrals_made,
      communication_profile_option_ids: [], social_interaction_profile_option_ids: [],
      autonomy_option_ids: [], accompaniment_option_ids: [], support_type_option_ids: [],
      iep_review_dates_attributes: [:id, :review_date, :_destroy],
      iep_attachments_attributes: [:id, :attachment, :attachment_cache, :_destroy],
      iep_curricular_plannings_attributes: [
        :id, :discipline_id, :knowledge_area_id, :school_term_type_step_id,
        :long_term_goal, :stage_objectives, :skills_to_develop, :methodologies, :_destroy,
        { instructional_accommodation_option_ids: [], environmental_accommodation_option_ids: [],
          assessment_accommodation_option_ids: [] }
      ],
      iep_periodic_evaluations_attributes: [
        :id, :discipline_id, :knowledge_area_id, :school_term_type_step_id,
        :acquired_skills, :in_progress_skills, :not_acquired_skills, :period_report,
        :next_stage_adjustments, :_destroy
      ]
    )
  end

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
