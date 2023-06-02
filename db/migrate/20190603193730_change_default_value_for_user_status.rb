class ChangeDefaultValueForUserStatus < ActiveRecord::Migration[4.2]
  def change
    change_column_default(:users, :status, 'active')
  end
end
