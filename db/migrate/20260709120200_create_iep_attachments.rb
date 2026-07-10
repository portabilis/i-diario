class CreateIepAttachments < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_attachments do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.string :attachment                       # CarrierWave (DocUploader)
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.string :attachment_file_size             # string "#{size} kB" (espelha TeachingPlanAttachment)
      t.datetime :attachment_updated_at

      t.timestamps
    end

    add_index :iep_attachments, :individualized_educational_plan_id,
              name: :idx_iep_attachments_on_iep

    add_foreign_key :iep_attachments, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
  end
end
