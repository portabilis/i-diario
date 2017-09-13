class AddSequenceToKnowledgeAreas < ActiveRecord::Migration
  def change
    add_column :knowledge_areas, :sequence, :integer
  end
end
