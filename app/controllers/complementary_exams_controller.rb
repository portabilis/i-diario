class ComplementaryExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy]

  def index
    step_id = (params[:filter] || []).delete(:by_step_id)

    set_options_by_user
    @complementary_exams = fetch_complementary_exams

    if step_id
      @complementary_exams = @complementary_exams.by_step_id(@classroom.map(&:id), step_id)
      params[:filter][:by_step_id] = step_id
    end

    authorize @complementary_exams
  end

  def new
    @complementary_exam = ComplementaryExam.new(
      unity: current_unity,
      classroom: current_user_classroom,
      discipline: current_user_discipline
    ).localized

    set_options_by_user
    fetch_disciplines_by_classroom
  end

  def create
    @complementary_exam = ComplementaryExam.new.localized
    @complementary_exam.assign_attributes(resource_params.to_h)
    @complementary_exam.step_number = @complementary_exam.step.try(:step_number)
    @complementary_exam.teacher_id = current_teacher_id

    authorize @complementary_exam

    if @complementary_exam.save
      respond_with @complementary_exam, location: complementary_exams_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom

      render :new
    end
  end

  def edit
    @complementary_exam = ComplementaryExam.find(params[:id])
    @complementary_exam.step_id = find_step_id
    @complementary_exam = @complementary_exam.localized

    set_options_by_user
    fetch_disciplines_by_classroom
    reload_students_list

    authorize @complementary_exam
  end

  def update
    @complementary_exam = ComplementaryExam.find(params[:id]).localized
    @complementary_exam.assign_attributes(resource_params.to_h)
    @complementary_exam.teacher_id = current_teacher_id
    @complementary_exam.current_user = current_user

    authorize @complementary_exam

    mark_students_not_found_for_destruction

    if @complementary_exam.save
      respond_with @complementary_exam, location: complementary_exams_path
    else
      set_options_by_user
      fetch_disciplines_by_classroom
      reload_students_list

      render :edit
    end
  end

  def destroy
    @complementary_exam = ComplementaryExam.find(params[:id])
    @complementary_exam.step_id = @complementary_exam.step.try(:id)
    @complementary_exam.destroy
    respond_with @complementary_exam, location: complementary_exams_path
  end

  def settings
    classroom = Classroom.find(params[:classroom_id])
    discipline = Discipline.find(params[:discipline_id])
    step = StepsFetcher.new(classroom).step_by_id(params[:step_id])

    render(json: _complementary_exam_settings(classroom, discipline, step))
  end

  def history
    @complementary_exam = ComplementaryExam.find(params[:id])

    authorize @complementary_exam

    respond_with @complementary_exam
  end

  private

  def resource_params
    params.require(:complementary_exam).permit(
      :complementary_exam_setting_id,
      :unity_id,
      :classroom_id,
      :step_id,
      :discipline_id,
      :recorded_at,
      students_attributes: [
        :id,
        :student_id,
        :score,
        :_destroy
      ]
    )
  end

  def find_step_id
    StepsFetcher.new(@complementary_exam.classroom).step(@complementary_exam.step_number).try(:id)
  end

  def complementary_exam_settings
    _complementary_exam_settings(current_user_classroom, current_user_discipline, @complementary_exam.try(:step), @complementary_exam.try(:id))
  end
  helper_method :complementary_exam_settings

  def _complementary_exam_settings(classroom, discipline, step, complementary_exam_id = nil)
    return [] unless classroom && discipline && step

    @complementary_exam_settings ||= ComplementaryExamSettingsFetcher.new(
      classroom,
      discipline,
      step,
      complementary_exam_id
    ).settings
  end
  helper_method :complementary_exam_settings

  def unities
    @unities ||= Unity.by_teacher(current_teacher.id).ordered
  end
  helper_method :unities

  def classrooms
    @classrooms ||= Classroom.where(id: current_user_classroom).ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines ||= Discipline.where(id: current_user_discipline).ordered
  end
  helper_method :disciplines

  def steps
    @steps ||= StepsFetcher.new(current_user_classroom).steps.ordered
  end
  helper_method :steps

  def fetch_student_enrollments
    return unless @complementary_exam.complementary_exam_setting && @complementary_exam.recorded_at

    @student_enrollments ||= StudentEnrollmentsList.new(
      classroom: @complementary_exam.classroom,
      discipline: @complementary_exam.discipline,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      show_inactive: false,
      with_recovery_note_in_step: @complementary_exam.complementary_exam_setting.affected_score == AffectedScoreTypes::STEP_RECOVERY_SCORE,
      date: @complementary_exam.recorded_at,
      status_attending: true,
      search_type: :by_date
    ).student_enrollments
  end

  def reload_students_list
    return unless @complementary_exam.recorded_at

    student_enrollments = fetch_student_enrollments

    return unless student_enrollments

    enrolled_student_ids = []

    student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        @complementary_exam.students.where(student_id: student.id).first || @complementary_exam.students.build(student_id: student.id, student: student)
        enrolled_student_ids << student.id
      end
    end

    @complementary_exam.students.select{ |student| !enrolled_student_ids.include?(student.student_id)}.each(&:mark_for_destruction)
  end

  def mark_students_not_found_for_destruction
    @complementary_exam.students.each do |student|
      student_exists = student.new_record? || resource_params[:students_attributes].any? do |student_params|
        student_params.last[:id].to_i == student.id
      end

      student.mark_for_destruction unless student_exists
    end
  end

  def fetch_complementary_exams
    apply_scopes(ComplementaryExam).includes(:complementary_exam_setting, :unity, :classroom, :discipline)
                                   .by_unity_id(current_unity.id)
                                   .by_classroom_id(@classrooms.map(&:id))
                                   .by_discipline_id(@disciplines.map(&:id))
                                   .ordered
  end

  def set_options_by_user
    if current_user.current_role_is_admin_or_employee?
      @classrooms ||= [current_user_classroom]
      @disciplines ||= [current_user_discipline]
    else
      fetch_linked_by_teacher
    end
  end

  def fetch_linked_by_teacher
    @fetch_linked_by_teacher ||= TeacherClassroomAndDisciplineFetcher.fetch!(current_teacher.id, current_unity, current_school_year)
    @classrooms ||= @fetch_linked_by_teacher[:classrooms]
    @disciplines ||= @fetch_linked_by_teacher[:disciplines]
    @exam_rules_ids ||= @fetch_linked_by_teacher[:classroom_grades].map(&:exam_rule_id)
  end

  def fetch_disciplines_by_classroom
    return if current_user.current_role_is_admin_or_employee?

    classroom = @complementary_exam.classroom
    @disciplines = @disciplines.by_classroom(classroom).not_descriptor
  end
end
