class StopAllStartedSynchronizations < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE ieducar_api_synchronizations SET status = 'completed' WHERE status = 'started';
    SQL
  end
end
