class CreateUnitySchoolDays < ActiveRecord::Migration
  def change
    create_table :unity_school_days do |t|
      t.references :unity, index: true, null: false
      t.date :school_day, null: false
    end
  end
end
