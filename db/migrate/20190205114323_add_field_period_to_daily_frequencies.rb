class AddFieldPeriodToDailyFrequencies < ActiveRecord::Migration
  def change
    add_column :daily_frequencies, :period, :integer
  end
end
