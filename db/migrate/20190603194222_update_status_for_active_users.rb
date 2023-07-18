class UpdateStatusForActiveUsers < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE users SET status = 'active' WHERE status = 'actived'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE users SET status = 'actived' WHERE status = 'active'
    SQL
  end
end
