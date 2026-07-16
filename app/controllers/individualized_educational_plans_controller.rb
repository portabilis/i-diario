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

  # Prefill da seção 1: dados de identificação do aluno (nascimento, diagnóstico, responsáveis, turno).
  def student_data
    student = Student.find(params[:student_id])

    render json: IndividualizedEducationalPlanPrefill.student_data(student, classroom: current_user_classroom)
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
    @individualized_educational_plan = IndividualizedEducationalPlan.includes(
      iep_curricular_plannings: [:discipline, :knowledge_area],
      iep_periodic_evaluations: [:discipline, :knowledge_area]
    ).find(params[:id])
    @individualized_educational_plan.unity_name = @individualized_educational_plan.unity&.name
    @individualized_educational_plan.classroom_name = @individualized_educational_plan.classroom&.description
    @individualized_educational_plan.teacher_name = @individualized_educational_plan.teacher&.name
    prefill_student_fields
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
  rescue ActiveRecord::RecordNotDestroyed => e
    # Remoção de data de revisão bloqueada (revisão com dados nas seções 4/5):
    @individualized_educational_plan.errors.add(:base, e.record.errors[:base].to_sentence)

    # O autosave interrompe na primeira falha; identifica TODAS as datas removidas que
    # possuem dados, para destacar cada input bloqueado (não só o primeiro).
    blocked_ids = @individualized_educational_plan.iep_review_dates
                                                  .select(&:marked_for_destruction?)
                                                  .select { |review|
                                                    review.iep_curricular_plannings.exists? ||
                                                      review.iep_periodic_evaluations.exists?
                                                  }.map(&:id)

    @individualized_educational_plan.iep_review_dates.reload
    @individualized_educational_plan.iep_review_dates.each do |review|
      review.errors.add(:review_date, :cannot_remove) if blocked_ids.include?(review.id)
    end

    set_form_options
    render :edit
  end

  def destroy
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])

    authorize @individualized_educational_plan

    @individualized_educational_plan.destroy

    respond_with @individualized_educational_plan, location: individualized_educational_plans_path
  end

  private

  # Professor da seção 1 = regente da turma (ref_cod_regente do i-Educar, sincronizado
  # em classrooms.regent_api_code). Sem regente cadastrado, cai no professor do perfil.
  def regent_teacher
    Teacher.find_by(api_code: current_user_classroom&.regent_api_code) || current_teacher
  end

  def prefill_student_fields
    return if @individualized_educational_plan.student.blank?

    data = IndividualizedEducationalPlanPrefill.student_data(
      @individualized_educational_plan.student,
      classroom: @individualized_educational_plan.classroom
    )
    @individualized_educational_plan.birth_date = data[:birth_date]
    @individualized_educational_plan.diagnosis = data[:diagnosis]
    @individualized_educational_plan.guardians = data[:guardians]
    @individualized_educational_plan.shift = data[:shift]
  end

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
    @iep_options_by_kind = IepOption.enabled.ordered.group_by(&:kind)
    @disciplines = Discipline.by_classroom_id(@classrooms.map(&:id)).ordered
    @knowledge_areas = KnowledgeArea.by_classroom_id(@classrooms.map(&:id)).ordered
  end

  def resource_params
    params.require(:individualized_educational_plan).permit(
      :student_id, :unity_id, :classroom_id, :teacher_id, :aee_teacher_id, :year,
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
