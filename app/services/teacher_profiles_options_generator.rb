class TeacherProfilesOptionsGenerator
  def initialize(user, year, unity_id)
    @year = year
    @teacher_id = user.teacher_id
    @unity_id = unity_id
  end

  def run!
    return [] unless @teacher_id

    Discipline.find_by_sql(<<-SQL, [[nil, @year], [nil, @teacher_id], [nil, @unity_id]])
      select * from (
        select
          classroom_id::text || '-' || min(discipline_id)::text as uuid,
          group_descriptors,
          knowledge_area_id,
          classroom_id,
          classrooms.description classroom_description,
          knowledge_areas.description,
          min(discipline_id) discipline_id,
          classrooms.label_color
        from disciplines
        inner join knowledge_areas on knowledge_areas.id = disciplines.knowledge_area_id
        inner join teacher_discipline_classrooms on teacher_discipline_classrooms.discipline_id = disciplines.id
        inner join classrooms on teacher_discipline_classrooms.classroom_id = classrooms.id
        WHERE true
        AND teacher_discipline_classrooms.year = $1
        AND teacher_id = $2
        AND unity_id = $3
        AND group_descriptors IS TRUE
        group by group_descriptors,
                 knowledge_area_id,
                 classroom_id,
                 classroom_description,
                 knowledge_areas.description,
                 classrooms.label_color
                 having min(discipline_id) > 1

        UNION

        select
          classroom_id::text || '-' || discipline_id::text as uuid,
          group_descriptors,
          knowledge_area_id,
          classroom_id,
          classrooms.description classroom_description,
          disciplines.description,
          discipline_id,
          classrooms.label_color
        from disciplines
        inner join knowledge_areas on knowledge_areas.id = disciplines.knowledge_area_id
        inner join teacher_discipline_classrooms on teacher_discipline_classrooms.discipline_id = disciplines.id
        inner join classrooms on teacher_discipline_classrooms.classroom_id = classrooms.id
        WHERE true
        AND teacher_discipline_classrooms.year = $1
        AND teacher_id = $2
        AND unity_id = $3
        AND group_descriptors IS FALSE) disciplines_and_knowledge_area
      order by
      classroom_description, description;
    SQL
  end
end
