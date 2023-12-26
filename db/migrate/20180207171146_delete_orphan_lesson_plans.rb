class DeleteOrphanLessonPlans < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE r record;
      BEGIN
        FOR r IN select ' delete from contents_lesson_plans '||
                        ' where contents_lesson_plans.lesson_plan_id = ' ||dados.id||';'||
                        ' delete from lesson_plans '||
                        ' where lesson_plans.id = ' ||dados.id||';' as script_to_execute
                from (select id
                      from lesson_plans
                      where ((select count(1)
                              from discipline_lesson_plans
                              where discipline_lesson_plans.lesson_plan_id = lesson_plans.id) +
                             (select count(1)
                              from knowledge_area_lesson_plans
                              where knowledge_area_lesson_plans.lesson_plan_id = lesson_plans.id)) = 0) dados
        LOOP
          EXECUTE r.script_to_execute;
        END LOOP;
      END$$;
    SQL
  end
end
