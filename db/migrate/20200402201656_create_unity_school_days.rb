class CreateUnitySchoolDays < ActiveRecord::Migration[4.2]
  def change
    create_table :unity_school_days do |t|
      t.references :unity, index: true, null: false
      t.date :school_day, null: false
    end
  end
end
