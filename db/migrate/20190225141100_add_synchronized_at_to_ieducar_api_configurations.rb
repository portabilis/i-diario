class AddSynchronizedAtToIeducarApiConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :ieducar_api_configurations, :synchronized_at, :datetime
  end
end
