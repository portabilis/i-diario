class ClassroomsController < ApplicationController
  respond_to :json

  def index
    if params[:find_by_current_teacher]
      teacher_id = current_teacher.try(:id)
      return unless teacher_id
    end

    if params[:find_by_current_year]
      year = current_school_calendar.try(:year)
    end

    score_type = params[:score_type]

    (params[:filter] || []).delete(:by_grade) if params.dig(:filter, :by_grade).blank?

    @classrooms = apply_scopes(Classroom).ordered

    @classrooms = @classrooms.includes(:unity) if params[:include_unity]
    @classrooms = @classrooms.by_teacher_id(teacher_id) if teacher_id
    @classrooms = @classrooms.by_score_type(ScoreTypes.value_for(score_type.upcase)) if score_type
    @classrooms = @classrooms.by_year(year) if year
    @classrooms = @classrooms.ordered.distinct
  end

  def classroom_grades
    index

    if @classrooms.any?
      grades = @classrooms.flat_map(&:classrooms_grades).map(&:grade).uniq

      render json: {
        classroom_grades: [@classrooms, grades]
      }
    else
      render json: { classroom_grades: [] }
    end
  end

  def multi_grade
    return false unless current_user.current_role_is_admin_or_employee?

    render json: current_user_classroom.multi_grade?
  end

  def by_unity
    return nil if params[:unity_id].blank?

    render json: classrooms_to_select2(params[:unity_id])
  end

  def classrooms_to_select2(unity_id)
    classrooms = Classroom.by_unity(unity_id)
                     .by_year(current_user_school_year || Date.current.year)
                     .ordered

    if current_user.teacher?
      classrooms = classrooms.by_teacher_id(current_teacher.id)
    end

    classrooms.map do |classroom|
      OpenStruct.new(
        id: classroom.id,
        name: classroom.description.to_s,
        text: classroom.description.to_s
      )
    end
  end

  def show
    return unless teacher_id = current_teacher.try(:id)
    id = params[:id]

    @classroom = Classroom.find_by_id(id)
  end
end
