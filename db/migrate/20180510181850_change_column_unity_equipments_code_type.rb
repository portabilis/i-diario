class ChangeColumnUnityEquipmentsCodeType < ActiveRecord::Migration
  def change
    change_column :unity_equipments, :code, :string
  end
end
