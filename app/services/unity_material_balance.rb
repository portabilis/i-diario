class Unity***REMOVED***Balance

  def initialize(unity)
    @unity = unity
  end

  def total_balance(material_id)
    total_balance = 0
    return 0 unless @unity
    @unity.moved_***REMOVED***.where(material_id: material_id).each do |moved_material|
      total_balance += moved_material.entrance_quantity || 0
      total_balance -= moved_material.exit_quantity || 0
    end
    total_balance
  end
end
