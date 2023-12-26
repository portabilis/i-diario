class CreateEntities < ActiveRecord::Migration[4.2]
  def change
    enable_extension :hstore

    create_table :entities do |t|
      t.string :name
      t.string :domain
      t.hstore :config

      t.timestamps
    end
    add_index :entities, :domain, unique: true
  end
end
