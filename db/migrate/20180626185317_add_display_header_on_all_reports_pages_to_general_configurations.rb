class AddDisplayHeaderOnAllReportsPagesToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :display_header_on_all_reports_pages, :boolean, default: false
  end
end
