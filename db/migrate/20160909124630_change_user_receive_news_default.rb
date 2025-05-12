class ChangeUserReceiveNewsDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default :users, :receive_news, true
    change_column_default :users, :receive_news_related_daily_teacher, true
    change_column_default :users, :receive_news_related_tools_for_parents, true
    change_column_default :users, :receive_news_related_all_matters, true
  end
end
