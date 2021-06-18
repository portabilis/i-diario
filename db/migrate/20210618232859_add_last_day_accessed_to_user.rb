class AddLastDayAccessedToUser < ActiveRecord::Migration
  def change
    add_column :users, :last_access, :date
  end
end
