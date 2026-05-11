class AddAllowActiveSearchFrequencyToGeneralConfigurations < ActiveRecord::Migration[5.0]
  def change
    add_column :general_configurations, :allow_active_search_frequency, :boolean, default: false
  end
end
