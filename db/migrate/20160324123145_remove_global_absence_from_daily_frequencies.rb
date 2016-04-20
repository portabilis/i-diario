class RemoveGlobalAbsenceFromDailyFrequencies < ActiveRecord::Migration
  def change
    remove_column :daily_frequencies, :global_absence
  end
end
