class AddReceiveNewsColumnsToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :receive_news, :boolean
    add_column :users, :receive_news_related_daily_teacher, :boolean
    add_column :users, :receive_news_related_tools_for_parents, :boolean
    add_column :users, :receive_news_related_all_matters, :boolean
  end
end
