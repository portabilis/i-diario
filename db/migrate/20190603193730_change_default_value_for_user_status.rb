class ChangeDefaultValueForUserStatus < ActiveRecord::Migration
  def change
    change_column_default(:users, :status, 'active')
  end
end
