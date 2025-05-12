class FixAvaliationIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :avaliations, :classroom_id
    remove_index :avaliations, :discipline_id
    remove_index :avaliations, :school_calendar_id
    remove_index :avaliations, :test_setting_id

    add_index :avaliations, :classroom_id, where: "deleted_at IS NULL"
    add_index :avaliations, :discipline_id, where: "deleted_at IS NULL"
    add_index :avaliations, :school_calendar_id, where: "deleted_at IS NULL"
    add_index :avaliations, :test_setting_id, where: "deleted_at IS NULL"
  end
end
