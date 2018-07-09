class CreateNotices < ActiveRecord::Migration
  def change
    create_table :notices do |t|
      t.string :kind
      t.text :text
      t.references :noticeable, polymorphic: true, index: true

      t.timestamps null: false
    end
  end
end
