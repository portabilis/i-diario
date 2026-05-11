class AddAllowActiveSearchFrequencyToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :allow_active_search_frequency, :boolean, default: false
  end
end
