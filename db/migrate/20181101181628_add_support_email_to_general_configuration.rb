class AddSupportEmailToGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :support_email, :string
  end
end
