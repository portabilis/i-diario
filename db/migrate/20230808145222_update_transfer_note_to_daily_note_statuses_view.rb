class UpdateTransferNoteToDailyNoteStatusesView < ActiveRecord::Migration[5.0]
  def up
    # Deleta view antiga e cria nova view utilizando a gem scenic
    execute <<-SQL
      DROP VIEW IF EXISTS daily_note_statuses;
    SQL

    create_view :daily_note_statuses
  end

  def down
    drop_view :daily_note_statuses
  end
end
