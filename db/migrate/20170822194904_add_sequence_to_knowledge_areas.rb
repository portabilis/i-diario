class AddSequenceToKnowledgeAreas < ActiveRecord::Migration[4.2]
  def change
    add_column :knowledge_areas, :sequence, :integer
  end
end
