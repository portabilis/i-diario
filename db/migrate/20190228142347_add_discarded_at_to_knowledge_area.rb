class AddDiscardedAtToKnowledgeArea < ActiveRecord::Migration
  def up
    add_column :knowledge_areas, :discarded_at, :datetime
    add_index :knowledge_areas, :discarded_at
  end

  def down
    remove_column :knowledge_areas, :discarded_at
  end
end
