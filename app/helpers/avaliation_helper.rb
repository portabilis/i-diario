module AvaliationHelper
  def show_avaliation_weight
    if @avaliation.test_setting.try(:arithmetic?)
      { class: 'hidden' }
    else
      {}
    end
  end

  def avaliation_data(avaliation)
    @classroom = avaliation.classroom
    @is_multi = @classroom.multi_grade?
    @grades = grades_by_classroom
    @input_value = if @classroom.multi_grade? && avaliation.grade_ids.empty?
                     ''
                   elsif avaliation.grade_ids.present?
                     avaliation.grade_ids.join(',')
                   else
                     @grades.first[:id]
                   end
  end

  def grades_by_classroom
    if @classroom.multi_grade?
      grades_to_select_2(ClassroomsGrade.includes(:grade)
                                        .by_classroom_id(@classroom.id)
                                        .by_score_type(ScoreTypes::NUMERIC)
                                        .order_by_grade_description)
    else
      grades_to_select_2(@classroom.first_classroom_grade)
    end
  end

  def grades_to_select_2(classroom_grades)
    grades = []

    if @classroom.multi_grade?
      classroom_grades.each do |classroom_grade|
        grades << build_grades(classroom_grade.grade)
      end
    else
      grades << build_grades(classroom_grades.grade)
    end

    grades
  end

  def build_grades(grade)
    { id: grade.id, name: grade.description, text: grade.description }
  end
end
