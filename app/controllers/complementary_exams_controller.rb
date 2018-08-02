class ComplementaryExamsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_teacher

  def index
    @complementary_exams = apply_scopes(ComplementaryExam)
      .includes(
        :complementary_exam_setting,
        :unity,
        :classroom,
        :discipline
      )
      .by_unity_id(current_user_unity.id)
      .by_classroom_id(current_user_classroom)
      .by_discipline_id(current_user_discipline)
      .ordered

    authorize @complementary_exams
  end

  def new
    @complementary_exam = ComplementaryExam.new.localized
    @complementary_exam.unity = current_user_unity


    @number_of_decimal_places = current_test_setting.number_of_decimal_places
  end

  def create
    @complementary_exam = ComplementaryExam.new.localized
    @complementary_exam.assign_attributes(resource_params)

    authorize @complementary_exam

    if @complementary_exam.save
      respond_with @complementary_exam, location: avaliation_recovery_diary_records_path
    else
      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list

      render :new
    end
  end

  def edit
    @complementary_exam = ComplementaryExam.find(params[:id]).localized

    authorize @complementary_exam

    add_missing_students
    mark_not_existing_students_for_destruction

    reload_students_list

    @number_of_decimal_places = current_test_setting.number_of_decimal_places
    @any_student_exempted_from_discipline = any_student_exempted_from_discipline?
  end

  def update
    @complementary_exam = ComplementaryExam.find(params[:id]).localized
    @complementary_exam.assign_attributes(resource_params)

    authorize @complementary_exam

    if @complementary_exam.save
      respond_with @complementary_exam, location: avaliation_recovery_diary_records_path
    else
      @number_of_decimal_places = current_test_setting.number_of_decimal_places
      reload_students_list

      render :edit
    end
  end

  def destroy
    @complementary_exams = ComplementaryExam.find(params[:id])

    @complementary_exams.destroy

    respond_with @complementary_exams, location: avaliation_recovery_diary_records_path
  end

  def settings
    classroom = Classroom.find(params[:classroom_id])
    discipline = Discipline.find(params[:discipline_id])
    step = StepsFetcher.new(classroom).steps.where(id: params[:step_id]).first
    _complementary_exam_settings(classroom, discipline, step)
  end

  private

  def resource_params
    params.require(:avaliation_recovery_diary_record).permit(
      :complementary_exam_setting_id,
      :unity_id,
      :classroom_id,
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

  def complementary_exam_settings
    _complementary_exam_settings(current_user_classroom, current_user_discipline, @complementary_exam.try(:step), @complementary_exam.try(:id))
  end
  helper_method :complementary_exam_settings


  def _complementary_exam_settings(classroom, discipline, step, complementary_exam_id = nil)
    return [] unless classroom && discipline && step

    @complementary_exam_settings ||= ComplementaryExamSettingFetcher.new(
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
    @classrooms ||= Classroom.where(id: current_user_classroom)
    .ordered
  end
  helper_method :classrooms

  def disciplines
    @disciplines ||= Discipline.where(id: current_user_discipline).ordered
  end
  helper_method :disciplines

  def mark_not_existing_students_for_destruction
    current_students.each do |current_student|
      is_student_in_recovery = daily_note_students.students.any? do |daily_note_student|
        current_student.student.id == daily_note_student.student.id
      end

      current_student.mark_for_destruction unless is_student_in_recovery
    end
  end

  def missing_students
    missing_students = []
    daily_note_students.students.each do |daily_note_student|
      is_missing = @complementary_exam.students.none? do |recovery_diary_record_student|
        recovery_diary_record_student.student.id == daily_note_student.student.id
      end
      missing_students << daily_note_student.student if is_missing
    end
    missing_students
  end

  def daily_note_students
    DailyNote.find_by_avaliation_id(@complementary_exams.avaliation_id)
  end

  def add_missing_students
    missing_students.each do |missing_student|
      @complementary_exam.students.build(student: missing_student)
    end
  end

  def current_students
    @complementary_exam.students
  end

  def fetch_student_enrollments
    return unless @complementary_exams.avaliation
    StudentEnrollmentsList.new(classroom: @complementary_exam.classroom,
                               discipline: @complementary_exam.discipline,
                               score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
                               date: @complementary_exam.recorded_at,
                               search_type: :by_date)
                          .student_enrollments
  end

  def reload_students_list
    student_enrollments = fetch_student_enrollments

    return unless fetch_student_enrollments
    return unless @complementary_exam.recorded_at

    @students = []

    student_enrollments.each do |student_enrollment|
      if student = Student.find_by_id(student_enrollment.student_id)
        note_student = (@complementary_exam.students.where(student_id: student.id).first || @complementary_exam.students.build(student_id: student.id, student: student))
        note_student.dependence = student_has_dependence?(student_enrollment, @complementary_exam.discipline)
        note_student.active = student_active_on_date?(student_enrollment)
        note_student.exempted_from_discipline = student_exempted_from_discipline?(student_enrollment, recovery_diary_record, @complementary_exams)
        @students << note_student
      end
    end

    @normal_students = []
    @dependence_students = []
    @any_inactive_student = any_inactive_student?

    @students.each do |student|
      @normal_students << student if !student.dependence
      @dependence_students << student if student.dependence
    end
  end

  def student_has_dependence?(student_enrollment, discipline)
    StudentEnrollmentDependence
      .by_student_enrollment(student_enrollment)
      .by_discipline(discipline)
      .any?
  end

  def student_active_on_date?(student_enrollment)
    StudentEnrollment
      .where(id: student_enrollment)
      .by_classroom(@complementary_exam.classroom)
      .by_date(@complementary_exam.recorded_at)
      .any?
  end

  def any_inactive_student?
    any_inactive_student = false
    if @students
      @students.each do |student|
        any_inactive_student = true if !student.active
      end
    end
    any_inactive_student
  end

  def student_exempted_from_discipline?(student_enrollment, recovery_diary_record, avaliation_recovery_diary_record)
    discipline_id = recovery_diary_record.discipline.id
    test_date = avaliation_recovery_diary_record.avaliation.test_date
    step_number = avaliation_recovery_diary_record.avaliation.school_calendar.step(test_date).to_number

    student_enrollment.exempted_disciplines.by_discipline(discipline_id)
                                           .by_step_number(step_number)
                                           .any?
  end

  def any_student_exempted_from_discipline?
    (@students || []).any?(&:exempted_from_discipline)
  end
end
