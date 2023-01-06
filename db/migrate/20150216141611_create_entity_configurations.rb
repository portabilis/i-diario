class CreateEntityConfigurations < ActiveRecord::Migration[4.2]
  def change
    create_table :entity_configurations do |t|
    	t.string :entity_name
    	t.string :cnpj
    	t.string :organ_name
    	t.string :phone
    	t.string :website
        t.string :email
    	t.string :logo

    	t.timestamps
    end
  end
end
