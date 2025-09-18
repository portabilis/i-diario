class AddIndexKnowledgeAreaGrouperToDisciplines < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  
  def up
    unless index_exists?(:disciplines, [:knowledge_area_id, :grouper], name: 'index_disciplines_on_knowledge_area_and_grouper')
      add_index :disciplines, [:knowledge_area_id, :grouper], 
                algorithm: :concurrently,
                name: 'index_disciplines_on_knowledge_area_and_grouper'
    end
  end
  
  def down
    if index_exists?(:disciplines, [:knowledge_area_id, :grouper], name: 'index_disciplines_on_knowledge_area_and_grouper')
      remove_index :disciplines, name: 'index_disciplines_on_knowledge_area_and_grouper'
    end
  end
end