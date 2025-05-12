class AbsenceMigrate < ActiveRecord::Migration[5.0]
  def change
    execute <<-SQL
      create temporary table absence_migrate as
      select
        dfs.id,
        dfs.absence_justification_student_id,
        ajs.id as new_id
      from absence_justifications aj
      inner join absence_justifications_students ajs
      on ajs.absence_justification_id = aj.id
      inner join daily_frequency_students dfs
      on dfs.absence_justification_student_id = aj.id
      and dfs.student_id <> ajs.student_id
      where aj.legacy = false;


      begin;

      update daily_frequency_students dfs
      set absence_justification_student_id = am.new_id
      from absence_migrate am
      where am.id = dfs.id;

      commit;
    SQL
  end
end
