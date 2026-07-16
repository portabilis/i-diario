class IndividualizedEducationalPlansController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher, only: [:index]
  before_action :require_current_classroom, only: [:index]

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

  def destroy
    @individualized_educational_plan = IndividualizedEducationalPlan.find(params[:id])

    authorize @individualized_educational_plan

    @individualized_educational_plan.destroy

    respond_with @individualized_educational_plan, location: individualized_educational_plans_path
  end

  private

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
