class ***REMOVED***StockMovmentCalc
  def self.balance(contract_id, commitment_id, supplier_id, material_id)
    contract_quantity = ***REMOVED******REMOVED******REMOVED***.joins(contract_commitment: :contract)
      .merge(***REMOVED******REMOVED***.where(contract_id: contract_id, commitment_id: commitment_id))
      .merge(***REMOVED***.where(supplier_id: supplier_id))
      .where(material_id: material_id).sum(:quantity)

    entrance_quantity = ***REMOVED***.joins(:material_entrance)
      .merge(***REMOVED***.where(supplier_id: supplier_id, contract_id: contract_id))
      .where(commitment_id: commitment_id, material_id: material_id).sum(:quantity)

    (contract_quantity - entrance_quantity)
  end
end
