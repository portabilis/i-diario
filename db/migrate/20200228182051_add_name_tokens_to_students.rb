class AddNameTokensToStudents < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      ALTER TABLE students add column name_tokens TSVECTOR;

      CREATE INDEX name_tokens_students_idx ON students USING GIST (name_tokens);

      UPDATE students
         SET name_tokens = to_tsvector('portuguese', name);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE students drop column name_tokens;
    SQL
  end
end
