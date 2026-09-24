class CreateMaterializedViewRefreshes < ActiveRecord::Migration[5.0]
  def change
    create_table :materialized_view_refreshes do |t|
      t.string :view_name, null: false
      t.datetime :refreshed_at, null: false
    end

    add_index :materialized_view_refreshes, :view_name, unique: true
  end
end
