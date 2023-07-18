class CreateInfrequencyTrackings < ActiveRecord::Migration[4.2]
  def change
    create_table :infrequency_trackings do |t|
      t.references :student, index: true, foreign_key: true
      t.references :classroom, index: true, foreign_key: true
      t.date :notification_date, null: false
      t.json :notification_data, null: false
      t.string :notification_type, null: false

      t.timestamps null: false
    end
  end
end
