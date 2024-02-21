class CreateAddresses < ActiveRecord::Migration[4.2]
  def change
    create_table :addresses do |t|
      t.integer :source_id
      t.string :source_type
      t.string :zip_code
      t.string :street
      t.integer :number
      t.string :complement
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :country
      t.string :latitude
      t.string :longitude

      t.timestamps
    end
    add_index :addresses, [:source_type, :source_id], unique: true
  end
end
