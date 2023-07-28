class UpdateDescriptorFieldOnDisciplines < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE disciplines d
         SET descriptor = true
        FROM knowledge_areas ka
       WHERE d.knowledge_area_id = ka.id
         AND ka.group_descriptors = true
    SQL
  end
end
