class AddShowExperienceFieldsToGeneralConfiguration < ActiveRecord::Migration
  def change
    add_column :general_configurations, :show_experience_fields, :boolean, default: false
  end
end
