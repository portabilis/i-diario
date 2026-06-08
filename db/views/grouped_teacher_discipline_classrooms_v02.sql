-- "Essa view serve apenas para identificar os registros de `teacher_discipline_classrooms`
  -- que devem ser removidos devido a disciplinas fakes órfãs"
SELECT tdc.id AS link_id, tdc.teacher_id, tdc.classroom_id
FROM teacher_discipline_classrooms tdc
INNER JOIN disciplines d ON d.id = tdc.discipline_id
INNER JOIN knowledge_areas ka ON ka.id = d.knowledge_area_id
WHERE tdc.discarded_at IS NULL
  AND tdc.active = true
  AND d.grouper = true
  AND ka.group_descriptors = true
  AND NOT EXISTS (
    SELECT 1 FROM teacher_discipline_classrooms regular
    INNER JOIN disciplines rd ON rd.id = regular.discipline_id
    WHERE regular.teacher_id = tdc.teacher_id
      AND regular.classroom_id = tdc.classroom_id
      AND regular.year = tdc.year
      AND regular.grade_id = tdc.grade_id
      AND regular.discarded_at IS NULL
      AND regular.active = true
      AND rd.knowledge_area_id = ka.id
      AND rd.grouper = false
  )
