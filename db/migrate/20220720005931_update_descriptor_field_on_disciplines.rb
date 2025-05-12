class UpdateDescriptorFieldOnDisciplines < ActiveRecord::Migration[4.2]
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
