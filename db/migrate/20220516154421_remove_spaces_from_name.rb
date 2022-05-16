class RemoveSpacesFromName < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE users SET first_name = BTRIM(first_name), last_name = BTRIM(last_name);
    SQL
  end
end
