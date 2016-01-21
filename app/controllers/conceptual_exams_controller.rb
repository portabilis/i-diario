class ConceptualExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_current_school_calendar

  def index
    @conceptual_exams = apply_scopes(ConceptualExam)
      .includes(
        :student,
        :conceptual_exam_values,
        classroom: :unity,
        school_calendar_step: :school_calendar
      )
      .filter(filtering_params(params[:search]))
      .by_unity(current_user_unity)
      .by_teacher(current_teacher)
      .ordered

    authorize @conceptual_exams

    fetch_classrooms
    fetch_school_calendar_steps
  end

  def new
    @conceptual_exam = ConceptualExam.new(
      unity_id: current_user_unity.id,
      recorded_at: Time.zone.today
    ).localized

    authorize @conceptual_exam

    fetch_unities_classrooms_disciplines_by_teacher
    fetch_classrooms
    fetch_school_calendar_steps
    fetch_students
  end

  def create
    @conceptual_exam = ConceptualExam.new(resource_params).localized

    authorize @conceptual_exam

    if @conceptual_exam.save
      respond_with @conceptual_exam, location: conceptual_exams_path
    else
      fetch_unities_classrooms_disciplines_by_teacher
      fetch_classrooms
      fetch_school_calendar_steps
      fetch_students

      render :new
    end
  end

  def edit
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.unity_id = @conceptual_exam.classroom.unity_id

    authorize @conceptual_exam

    fetch_unities_classrooms_disciplines_by_teacher
    fetch_classrooms
    fetch_school_calendar_steps
    fetch_students
  end

  def update
    @conceptual_exam = ConceptualExam.find(params[:id]).localized
    @conceptual_exam.assign_attributes(resource_params)

    authorize @conceptual_exam

    if @conceptual_exam.save
      respond_with @conceptual_exam, location: conceptual_exams_path
    else
      fetch_unities_classrooms_disciplines_by_teacher
      fetch_classrooms
      fetch_school_calendar_steps
      fetch_students

      render :edit
    end
  end

  def destroy
    @conceptual_exam = ConceptualExam.find(params[:id]).localized

    authorize @conceptual_exam

    @conceptual_exam.destroy

    respond_with @conceptual_exam, location: conceptual_exams_path
  end

  def history
    @conceptual_exam = ConceptualExam.find(params[:id]).localized

    authorize @conceptual_exam

    respond_with @conceptual_exam
  end

  private

  def resource_params
    params.require(:conceptual_exam).permit(
      :unity_id,
      :classroom_id,
      :school_calendar_step_id,
      :recorded_at,
      :student_id,
      conceptual_exam_values_attributes: [
        :id,
        :discipline_id,
        :value
      ]
    )
  end

  def filtering_params(params)
    params = {} unless params
    params.slice(
      :by_classroom,
      :by_student_name,
      :by_school_calendar_step,
      :by_status
    )
  end

  def configuration
    @configuration ||= IeducarApiConfiguration.current
  end

  def fetch_classrooms
    @classrooms = Classroom.by_teacher_id(current_teacher.id)
    .by_unity(current_user_unity)
    .by_teacher_id(current_teacher)
    .by_score_type(ScoreTypes::CONCEPT)
  end

  def fetch_unities_classrooms_disciplines_by_teacher
    fetcher = UnitiesClassroomsDisciplinesByTeacher.new(
      current_teacher.id,
      @conceptual_exam.try(:classroom).try(:unity_id) || @conceptual_exam.try(:unity_id),
      @conceptual_exam.classroom_id
    )
    fetcher.fetch!

    @unities = fetcher.unities
    @disciplines = fetcher.disciplines
  end

  def fetch_school_calendar_steps
    @school_calendar_steps = current_school_calendar.steps
  end

  def fetch_students
    @students = []

    if @conceptual_exam.classroom.present? && @conceptual_exam.recorded_at.present?
      begin
        @students = StudentsFetcher.new(
          configuration,
          @conceptual_exam.classroom.api_code,
          date: @conceptual_exam.recorded_at.to_date.to_s
        )
        .fetch
      rescue IeducarApi::Base::ApiError => e
        flash[:alert] = e.message
        render :new
      end
    end
  end
end
