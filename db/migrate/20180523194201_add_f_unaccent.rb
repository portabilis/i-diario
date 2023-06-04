class AddFUnaccent < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION f_unaccent(text)
        RETURNS text AS
      $func$
      SELECT public.unaccent('public.unaccent', $1)  -- schema-qualify function and dictionary
      $func$  LANGUAGE sql IMMUTABLE;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION f_unaccent(text);
    SQL
  end
end
