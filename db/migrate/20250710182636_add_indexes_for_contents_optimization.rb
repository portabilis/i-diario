class AddIndexesForContentsOptimization < ActiveRecord::Migration
  disable_ddl_transaction!
  
  def change
    # Índice para queries exatas em description (find_or_create_by)
    add_index :contents, :description, 
              name: 'index_contents_on_description',
              algorithm: :concurrently
    
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