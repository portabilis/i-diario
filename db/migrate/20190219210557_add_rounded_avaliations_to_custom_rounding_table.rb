class AddRoundedAvaliationsToCustomRoundingTable < ActiveRecord::Migration[4.2]
  def change
    add_column :custom_rounding_tables, :rounded_avaliations, :string, array: true,
      default: RoundedAvaliations.list
  end
end
