class AddSynchronizedAtToIeducarApiConfigurations < ActiveRecord::Migration
  def change
    add_column :ieducar_api_configurations, :synchronized_at, :datetime
  end
end
