module ComplementaryExamSettingHelper
  def grades_to_select2(grades)
    grades.map { |grade|
      OpenStruct.new(
        id: grade.id,
        name: "#{grade.description} - #{grade.course.description}",
        text: "#{grade.description} - #{grade.course.description}"
      )
    }
  end
end
