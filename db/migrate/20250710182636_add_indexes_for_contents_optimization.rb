class AddIndexesForContentsOptimization < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    # Índice hash para queries exatas em description (find_or_create_by)
    # Usa HASH pois algumas descrições excedem o limite do B-tree (2704 bytes)
    execute <<-SQL
      CREATE INDEX CONCURRENTLY index_contents_on_description 
      ON contents USING hash (description);
    SQL
    
    # Índice para ordenação por created_at (usado em start_with_description)
    add_index :contents, :created_at, 
              name: 'index_contents_on_created_at',
              algorithm: :concurrently
    
    # Índices compostos para queries ordenadas por position nas tabelas de join
    add_index :contents_teaching_plans, [:teaching_plan_id, :position], 
              name: 'index_contents_teaching_plans_on_plan_and_position',
              algorithm: :concurrently
    
    add_index :contents_lesson_plans, [:lesson_plan_id, :position], 
              name: 'index_contents_lesson_plans_on_plan_and_position',
              algorithm: :concurrently
  end
end