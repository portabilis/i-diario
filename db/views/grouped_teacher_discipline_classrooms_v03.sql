-- Identifica os vínculos de teacher_discipline_classrooms com disciplina agrupadora (fake) que
-- ficaram órfãos: sem nenhuma disciplina regular ativa da mesma área de conhecimento para o
-- mesmo professor/turma/ano/série.
--
-- Sem filtro por knowledge_areas.group_descriptors: o vínculo agrupador órfão precisa ser
-- removido independentemente de a flag de agrupamento estar ligada ou desligada na área.
SELECT tdc.id AS link_id, tdc.teacher_id, tdc.classroom_id
FROM teacher_discipline_classrooms tdc
INNER JOIN disciplines d ON d.id = tdc.discipline_id
WHERE tdc.discarded_at IS NULL
  AND tdc.active = true
  AND d.grouper = true
  AND d.knowledge_area_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM teacher_discipline_classrooms regular
    INNER JOIN disciplines rd ON rd.id = regular.discipline_id
    WHERE regular.teacher_id = tdc.teacher_id
      AND regular.classroom_id = tdc.classroom_id
      AND regular.year = tdc.year
      -- IS NOT DISTINCT FROM porque vínculos antigos têm `grade_id` nulo: com `=` a comparação
      -- retornaria NULL e o agrupador seria considerado órfão indevidamente
      AND regular.grade_id IS NOT DISTINCT FROM tdc.grade_id
      AND regular.discarded_at IS NULL
      AND regular.active = true
      AND rd.knowledge_area_id = d.knowledge_area_id
      -- IS NOT TRUE (e não = false) para contar como regular também disciplinas com grouper nulo
      AND rd.grouper IS NOT TRUE
  )
