class AddSupportUrlToGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :support_url, :string
  end
end
