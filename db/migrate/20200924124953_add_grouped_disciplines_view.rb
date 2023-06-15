class AddGroupedDisciplinesView < ActiveRecord::Migration[4.2]
  def change
    execute(<<-SQL)
      CREATE OR REPLACE VIEW grouped_disciplines AS
      SELECT *
      FROM
        (SELECT classroom_id::text || '-' || min(discipline_id)::text AS uuid,
                group_descriptors,
                knowledge_area_id,
                classroom_id,
                classrooms.description classroom_description,
                knowledge_areas.description,
                min(discipline_id) discipline_id,
                classrooms.label_color,
                classrooms.year,
                classrooms.unity_id,
                teacher_discipline_classrooms.teacher_id
        FROM disciplines
        INNER JOIN knowledge_areas ON knowledge_areas.id = disciplines.knowledge_area_id
        INNER JOIN teacher_discipline_classrooms ON teacher_discipline_classrooms.discipline_id = disciplines.id
        INNER JOIN classrooms ON teacher_discipline_classrooms.classroom_id = classrooms.id
        WHERE TRUE
          AND classrooms.discarded_at IS NULL
          AND group_descriptors IS TRUE
        GROUP BY group_descriptors,
                  knowledge_area_id,
                  classroom_id,
                  classroom_description,
                  knowledge_areas.description,
                  classrooms.label_color,
                  classrooms.year,
                  classrooms.unity_id,
                  teacher_discipline_classrooms.teacher_id
        UNION SELECT classroom_id::text || '-' || discipline_id::text AS uuid,
                      group_descriptors,
                      knowledge_area_id,
                      classroom_id,
                      classrooms.description classroom_description,
                      disciplines.description,
                      discipline_id,
                      classrooms.label_color,
                      classrooms.year,
                      classrooms.unity_id,
                      teacher_discipline_classrooms.teacher_id
        FROM disciplines
        INNER JOIN knowledge_areas ON knowledge_areas.id = disciplines.knowledge_area_id
        INNER JOIN teacher_discipline_classrooms ON teacher_discipline_classrooms.discipline_id = disciplines.id
        INNER JOIN classrooms ON teacher_discipline_classrooms.classroom_id = classrooms.id
        WHERE TRUE
          AND classrooms.discarded_at IS NULL
          AND group_descriptors IS FALSE) disciplines_and_knowledge_area
      ORDER BY classroom_description,
              description;
    SQL
  end
end
