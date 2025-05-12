class CreateLessonsBoards < ActiveRecord::Migration[4.2]
  def change
    create_table :lessons_boards do |t|
      t.integer :classroom_id
      t.integer :period
      t.timestamps
      t.datetime :discarded_at
    end
    add_index :lessons_boards, [:classroom_id, :period], unique: true
    add_foreign_key :lessons_boards, :classrooms, column: :classroom_id
  end
end
