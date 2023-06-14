class CreateLessonsBoardLessons < ActiveRecord::Migration[4.2]
  def change
    create_table :lessons_board_lessons do |t|
      t.integer :lessons_board_id
      t.string :lesson_number
      t.timestamps
      t.datetime :discarded_at
    end
    add_index :lessons_board_lessons, :lessons_board_id
    add_foreign_key :lessons_board_lessons, :lessons_boards, column: :lessons_board_id
  end
end
