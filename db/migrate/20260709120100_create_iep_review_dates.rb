class CreateIepReviewDates < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_review_dates do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.date :review_date, null: false

      t.timestamps
    end

    add_index :iep_review_dates, :individualized_educational_plan_id,
              name: :idx_iep_review_dates_on_iep

    add_foreign_key :iep_review_dates, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
  end
end
