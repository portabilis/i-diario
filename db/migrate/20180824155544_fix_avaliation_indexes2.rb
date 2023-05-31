class FixAvaliationIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :avaliations, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :avaliations, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :avaliations, column: [:school_calendar_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :avaliations, column: [:test_setting_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :avaliations, :classroom_id, algorithm: :concurrently
    add_index :avaliations, :discipline_id, algorithm: :concurrently
    add_index :avaliations, :school_calendar_id, algorithm: :concurrently
    add_index :avaliations, :test_setting_id, algorithm: :concurrently
  end
end
