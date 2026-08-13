-- "Essa view serve apenas para identificar os registros de `teacher_discipline_classrooms`
  -- que devem ser removidos devido a disciplinas fakes órfãs"
--
-- Um vínculo agrupador é órfão quando não existe nenhuma disciplina regular ativa da mesma
-- área de conhecimento para o mesmo professor/turma/ano/série. Isso independe da flag
-- `group_descriptors` da área: quando a rede desliga o agrupamento no i-Educar, os vínculos
-- agrupadores que sobraram também precisam ser removidos — por isso a view não filtra por ela.
SELECT tdc.id AS link_id, tdc.teacher_id, tdc.classroom_id
FROM teacher_discipline_classrooms tdc
INNER JOIN disciplines d ON d.id = tdc.discipline_id
WHERE tdc.discarded_at IS NULL
  AND tdc.active = true
  AND d.grouper = true
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
      AND rd.grouper = false
  )
