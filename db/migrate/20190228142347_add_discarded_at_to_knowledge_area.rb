class AddDiscardedAtToKnowledgeArea < ActiveRecord::Migration
  def change
    add_column :knowledge_areas, :discarded_at, :datetime
    add_index :knowledge_areas, :discarded_at
  end
end
