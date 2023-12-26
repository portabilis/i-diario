class PopulateUsersFullname < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      update users set fullname = UNACCENT(TRIM(coalesce(first_name, '') || ' ' || coalesce(last_name, '')));
    SQL
  end
end
