class DestroyDuplicatedGroupedLinkService
  def self.call
    ActiveRecord::Base.transaction do
      ids = ActiveRecord::Base.connection.select_values(<<-SQL)
        SELECT tdc.id
        FROM teacher_discipline_classrooms tdc
        INNER JOIN (
          SELECT tdc.teacher_id, tdc.classroom_id, tdc.grade_id, ka.id AS knowledge_area_id,
                (SELECT id FROM disciplines
                    WHERE knowledge_area_id = ka.id AND grouper = true LIMIT 1) AS grouper_id, COUNT(*)
          FROM teacher_discipline_classrooms tdc
          INNER JOIN disciplines d ON d.id = tdc.discipline_id
          INNER JOIN knowledge_areas ka ON ka.id = d.knowledge_area_id
          WHERE true
            AND tdc.discarded_at IS NULL
            AND ka.group_descriptors = true
            AND d.grouper = true
          GROUP BY tdc.teacher_id, tdc.classroom_id, tdc.grade_id, ka.id
          HAVING COUNT(*) > 1
        ) AS g
        ON tdc.teacher_id = g.teacher_id
        AND tdc.classroom_id = g.classroom_id
        AND tdc.grade_id = g.grade_id
        AND tdc.discipline_id = g.grouper_id
      SQL
      TeacherDisciplineClassroom.where(id: ids).find_each(&:destroy)
    end
  end
end
