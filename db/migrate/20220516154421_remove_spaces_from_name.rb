class RemoveSpacesFromName < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE users SET first_name = trim(regexp_replace(first_name, '\s+', ' ', 'g')),
                       last_name = trim(regexp_replace(last_name, '\s+', ' ', 'g'))
    SQL
  end
end
