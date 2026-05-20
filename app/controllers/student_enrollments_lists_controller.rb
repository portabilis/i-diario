class StudentEnrollmentsListsController < ApplicationController
  before_action :adjusted_period
  before_action :validate_date_param, only: :by_date

  def by_date
    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:filter][:classroom],
      discipline: params[:filter][:discipline],
      score_type: params[:filter][:score_type],
      opinion_type: params[:filter][:opinion_type],
      show_inactive: ActiveRecord::Type::Boolean.new.cast(params[:filter][:show_inactive]),
      with_recovery_note_in_step: ActiveRecord::Type::Boolean.new.cast(
        params[:filter][:with_recovery_note_in_step]
      ),
      date: params[:filter][:date],
      period: @period,
      status_attending: params[:filter][:status_attending]
    ).student_enrollments

    assign_student_situations(student_enrollments)

    render json: student_enrollments
  end

  def by_date_range
    student_enrollments = StudentEnrollmentsList.new(
      classroom: params[:filter][:classroom],
      discipline: params[:filter][:discipline],
      start_at: params[:filter][:start_at],
      end_at: params[:filter][:end_at],
      score_type: params[:filter][:score_type],
      opinion_type: params[:filter][:opinion_type],
      search_type: :by_date_range,
      show_inactive: ActiveRecord::Type::Boolean.new.cast(params[:filter][:show_inactive]),
      period: @period
    ).student_enrollments

    render json: student_enrollments
  end

  private

  def assign_student_situations(student_enrollments)
    return if student_enrollments.blank?

    date = params[:filter][:date].to_date
    enrollment_ids = student_enrollments.map(&:id)

    enrollments_in_active_search =
      ActiveSearch.new.enrollments_in_active_search?(enrollment_ids, date)[date] || []
    dependencies = StudentsInDependency.call(
      student_enrollments: enrollment_ids,
      disciplines: params[:filter][:discipline]
    )
    active_on_date_ids = StudentEnrollment.where(id: enrollment_ids)
                                          .by_classroom(params[:filter][:classroom])
                                          .by_date(date)
                                          .pluck(:id)
                                          .to_set

    student_enrollments.each do |student_enrollment|
      student_enrollment.in_active_search = enrollments_in_active_search.include?(student_enrollment.id)
      student_enrollment.in_dependence = dependencies[student_enrollment.id].present?
      student_enrollment.inactive_on_date = !active_on_date_ids.include?(student_enrollment.id)
    end
  end

  def validate_date_param
    validator = DateParamValidator.new(params[:filter][:date])

    return if validator.valid?

    render json: { errors: validator.errors.full_messages }, status: :unprocessable_entity
  end

  def current_teacher_period
    admin_or_teacher = current_user.current_role_is_admin_or_employee?
    classroom_id = admin_or_teacher ? current_user.current_classroom_id : params[:filter][:classroom]
    discipline_id = admin_or_teacher ? current_user.current_discipline_id : params[:filter][:discipline]

    TeacherPeriodFetcher.new(
      current_teacher.id,
      classroom_id,
      discipline_id
    ).teacher_period
  end

  def adjusted_period
    teacher_period = current_teacher_period
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil
  end
end
