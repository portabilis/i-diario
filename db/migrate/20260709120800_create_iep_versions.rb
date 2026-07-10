class CreateIepVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_versions do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.integer :published_by_id, null: false          # user que publicou
      t.string :name, null: false
      t.datetime :published_at, null: false
      t.boolean :active, null: false, default: false   # só uma ativa por PEI (garantido no publisher)
      t.jsonb :content, null: false, default: {}        # snapshot completo do PEI no momento da publicação

      t.timestamps
    end

    add_index :iep_versions, :individualized_educational_plan_id,
              name: :idx_iep_versions_on_iep
    add_index :iep_versions, [:individualized_educational_plan_id, :active],
              name: :idx_iep_versions_on_iep_and_active

    add_foreign_key :iep_versions, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
    add_foreign_key :iep_versions, :users, column: :published_by_id
  end
end
