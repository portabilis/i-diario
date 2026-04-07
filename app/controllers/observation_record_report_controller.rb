class ObservationRecordReportController < ApplicationController
  before_action :require_current_teacher

  def form
    @observation_record_report_form = ObservationRecordReportForm.new(
      unity_id: current_unity.id,
      start_at: Time.zone.today,
      end_at: Time.zone.today,
      current_user_id: current_user.id,
      current_teacher_id: current_teacher.id
    ).localized
  end

  def report
    @observation_record_report_form = ObservationRecordReportForm.new(
      resource_params
    )
    .localized

    if @observation_record_report_form.valid?
      observation_record_report = ObservationRecordReport.new(
          current_entity_configuration,
          @observation_record_report_form
        )
        .build
        send_pdf(t("routes.observation_record"), observation_record_report.render)
    else
      clear_invalid_dates
      render :form
    end
  end

  def unities
    if current_user.current_user_role.try(:role_administrator?)
      Unity.ordered
    else
      [current_user_unity]
    end
  end
  helper_method :unities

  def disciplines
    disciplines = if params[:classroom_id] == 'all'
                    return render json: { disciplines: [] } if params[:unity_id].blank?

                    fetch_disciplines_for_all_classrooms
                  else
                    return render json: { disciplines: [] } if params[:classroom_id].blank?

                    fetch_disciplines_for_classroom
                  end

    render json: {
      disciplines: disciplines.map do |discipline|
        {
          id: discipline.id,
          name: discipline.description.to_s,
          text: discipline.description.to_s
        }
      end
    }
  end

  def teachers
    return render json: { teachers: [] } if params[:classroom_id].blank? || params[:classroom_id] == 'all'

    teachers = Teacher.by_classroom(params[:classroom_id]).active.order_by_name.distinct

    render json: {
      teachers: teachers.map { |teacher| { id: teacher.id, name: teacher.name, text: teacher.name } }
    }
  end

  def students
    return render json: { students: [] } if params[:classroom_id].blank? || params[:classroom_id] == 'all'

    student_ids = StudentEnrollment.by_classroom(params[:classroom_id])
                                   .active
                                   .pluck(:student_id)
                                   .uniq

    students = Student.where(id: student_ids).ordered

    render json: {
      students: students.map { |student| { id: student.id, name: student.name, text: student.name } }
    }
  end

  private

  def fetch_disciplines_for_all_classrooms
    if current_user.teacher?
      Discipline.by_unity_id(params[:unity_id], current_school_year)
                .by_teacher_id(current_teacher.id, current_school_year)
                .not_descriptor
    else
      Discipline.by_unity_id(params[:unity_id], current_school_year).not_descriptor
    end
  end

  def fetch_disciplines_for_classroom
    if current_user.teacher?
      Discipline.by_classroom_id(params[:classroom_id])
                .by_teacher_id(current_teacher.id, current_school_year)
                .not_descriptor
    else
      Discipline.by_classroom_id(params[:classroom_id]).not_descriptor
    end
  end

  def resource_params
    params.require(:observation_record_report_form).permit(
      :teacher_id,
      :unity_id,
      :classroom_id,
      :discipline_id,
      :student_id,
      :start_at,
      :end_at,
      :current_user_id,
      :current_teacher_id
    )
  end

  def clear_invalid_dates
    start_at = resource_params[:start_at]
    end_at = resource_params[:end_at]

    @observation_record_report_form.start_at = '' unless start_at.try(:to_date)
    @observation_record_report_form.end_at = '' unless end_at.try(:to_date)
  end
end
