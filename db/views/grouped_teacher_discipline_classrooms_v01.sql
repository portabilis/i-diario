select tdc.id as link_id, tdc.teacher_id, tdc.classroom_id
from teacher_discipline_classrooms tdc 
  inner join (
    select 
      tdc.teacher_id,
      tdc.classroom_id, 
      ka.id as knowledge_area_id, 
      (select id from disciplines where knowledge_area_id = ka.id and grouper = true limit 1) as grouper_id, 
      count(*)
    from teacher_discipline_classrooms tdc 
    inner join disciplines d 
    on d.id = tdc.discipline_id
    inner join knowledge_areas ka 
    on ka.id = d.knowledge_area_id
    where true and tdc.discarded_at is null 
    and ka.group_descriptors = true
    group by tdc.teacher_id, tdc.classroom_id, ka.id
    having count(*) = 1
  ) as g
on tdc.teacher_id = g.teacher_id
and tdc.classroom_id = g.classroom_id
and tdc.discipline_id = g.grouper_id