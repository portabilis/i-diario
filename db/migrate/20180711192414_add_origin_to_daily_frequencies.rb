class AddOriginToDailyFrequencies < ActiveRecord::Migration
  def change
    add_column :daily_frequencies, :origin, :string
  end
end
