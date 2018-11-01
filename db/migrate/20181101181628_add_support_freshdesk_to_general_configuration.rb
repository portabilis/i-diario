class AddSupportFreshdeskToGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :support_freshdesk, :string
  end
end
