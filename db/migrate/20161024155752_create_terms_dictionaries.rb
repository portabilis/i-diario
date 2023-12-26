class CreateTermsDictionaries < ActiveRecord::Migration[4.2]
  def change
    create_table :terms_dictionaries do |t|
      t.string :presence_identifier_character, length: 1, null: false

      t.timestamps null: false
    end
  end
end
