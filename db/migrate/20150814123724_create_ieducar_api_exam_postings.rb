class CreateIeducarApiExamPostings < ActiveRecord::Migration[4.2]
  def change
    create_table :ieducar_api_exam_postings do |t|
      t.integer :ieducar_api_configuration_id
      t.string :post_type
      t.string :status
      t.integer :author_id
      t.integer :school_calendar_step_id
      t.text :message
      t.text :error_message
      t.boolean :notified, default: false

      t.timestamps
    end

    add_index :ieducar_api_exam_postings, :author_id
    add_foreign_key :ieducar_api_exam_postings, :users, column: :author_id

    add_index :ieducar_api_exam_postings, :ieducar_api_configuration_id
    add_foreign_key :ieducar_api_exam_postings, :ieducar_api_configurations

    add_index :ieducar_api_exam_postings, :school_calendar_step_id
    add_foreign_key :ieducar_api_exam_postings, :school_calendar_steps
  end
end
