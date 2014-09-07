class CreateIeducarApiConfigurations < ActiveRecord::Migration
  def change
    create_table :ieducar_api_configurations do |t|
      t.string :url, null: false
      t.string :token, null: false
      t.string :secret_token, null: false
      t.string :unity_code, null: false

      t.timestamps
    end
  end
end
