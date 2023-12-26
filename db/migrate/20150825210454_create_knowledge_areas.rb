class CreateKnowledgeAreas < ActiveRecord::Migration[4.2]
  def change
    create_table :knowledge_areas do |t|
      t.string :description
      t.string :api_code

      t.timestamps
    end

    add_column :disciplines, :knowledge_area_id, :integer
    add_index :disciplines, :knowledge_area_id
    add_foreign_key :disciplines, :knowledge_areas
  end
end
