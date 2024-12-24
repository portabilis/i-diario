class ChangeColumnUnityEquipmentsCodeType < ActiveRecord::Migration[4.2]
  def change
    change_column :unity_equipments, :code, :string
  end
end
