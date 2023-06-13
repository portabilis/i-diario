class AddDisplayHeaderOnAllReportsPagesToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :display_header_on_all_reports_pages, :boolean, default: false
  end
end
