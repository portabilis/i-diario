class CreateGeneralConfigurations < ActiveRecord::Migration
  def change
    create_table :general_configurations do |t|
      t.string :security_level, null: false, default: 'basic'

      t.timestamps
    end
    add_index :general_configurations, :security_level
  end
end
