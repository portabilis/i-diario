class CreateLessonsBoardLessonWeekdays < ActiveRecord::Migration[4.2]
  def change
    create_table :lessons_board_lesson_weekdays do |t|
      t.integer :lessons_board_lesson_id
      t.string :weekday, null: false
      t.integer :teacher_discipline_classroom_id
      t.timestamps
      t.datetime :discarded_at
    end
    add_index :lessons_board_lesson_weekdays, :lessons_board_lesson_id
    add_foreign_key :lessons_board_lesson_weekdays, :lessons_board_lessons, column: :lessons_board_lesson_id
  end
end
