class PopulateUsersFullname < ActiveRecord::Migration
  def change
    execute <<-SQL
      update users set fullname = UNACCENT(TRIM(coalesce(first_name, '') || ' ' || coalesce(last_name, '')));
    SQL
  end
end
