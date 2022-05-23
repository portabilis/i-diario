class RemoveSpacesFromName < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE users SET first_name = trim(regexp_replace(first_name, '\s+', ' ', 'g')),
                       last_name = trim(regexp_replace(last_name, '\s+', ' ', 'g'))
    SQL
  end
end
