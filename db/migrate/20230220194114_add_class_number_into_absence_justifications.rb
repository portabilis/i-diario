class AddClassNumberIntoAbsenceJustifications < ActiveRecord::Migration
  def change
    add_column :absence_justifications, :class_number, :integer, null: true
  end
end
