class LessonBoardsService
  def teachers(classroom_id, period)
    teachers_to_select2 = []
    classroom_period = Classroom.find(classroom_id).period
    allocations = TeacherDisciplineClassroom.where(classroom_id: classroom_id)
                                            .includes(:teacher, discipline: :knowledge_area)
                                            .where(disciplines: { descriptor: false })
                                            .order('teachers.name')

    period = Array([period.to_i]) if period != 3
    allocations.where(period: period) if classroom_period == Periods::FULL && period

    allocations.each do |teacher_discipline_classroom|
      teachers_to_select2 << OpenStruct.new(
        id: teacher_discipline_classroom.id,
        name: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                      teacher_discipline_classroom.teacher.name.try(:strip)),
        text: discipline_teacher_name(teacher_discipline_classroom.discipline,
                                      teacher_discipline_classroom.teacher.name.try(:strip))
      )
    end

    teachers_to_select2.insert(0, OpenStruct.new(id: 'empty', name: '<option></option>', text: ''))
  end

  private

  def discipline_teacher_name(discipline, teacher)
    "<div class='flex-between'>
       <div class='flex-teacher'>
          <div>
            #{teacher.upcase}
          </div>
       </div>
       <div class='flex-discipline'>
         <span class='flex-discipline-span' style='background-color: #{discipline.label_color};'>
           #{discipline.description.try(:strip)}
         </span>
       </div>
     </div>"
  end
end
