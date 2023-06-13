class CreateActiveSearch < ActiveRecord::Migration[4.2]
  def change
    create_table :active_searches do |t|
      t.belongs_to :student_enrollment
      t.date :start_date, null: false
      t.date :end_date
      t.integer :status, null: false
      t.string :observations

      t.timestamps
    end
  end
end
