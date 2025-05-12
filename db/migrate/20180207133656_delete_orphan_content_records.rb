class DeleteOrphanContentRecords < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DO $$DECLARE r record;
      BEGIN
        FOR r IN select ' delete from contents_content_records '||
                        ' where contents_content_records.content_record_id = ' ||dados.id||';'||
                        ' delete from content_records_contents '||
                        ' where content_records_contents.content_record_id = ' ||dados.id||';'||
                        ' delete from content_records '||
                        ' where content_records.id = ' ||dados.id||';' as script_to_execute
                from (select id
                      from content_records
                      where ((select count(1)
                              from discipline_content_records
                              where discipline_content_records.content_record_id = content_records.id) +
                             (select count(1)
                              from knowledge_area_content_records
                              where knowledge_area_content_records.content_record_id = content_records.id)) = 0) dados
        LOOP
          EXECUTE r.script_to_execute;
        END LOOP;
      END$$;
    SQL
  end
end
