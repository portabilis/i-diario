class StockMovementCalc
  def self.balance(unity_id, material_id, start_date)
    entrances = ***REMOVED***(unity_id, material_id, '1900-01-01', start_date.to_date-1).sum(:quantity)
    exits = ***REMOVED***(unity_id, material_id, '1900-01-01', start_date.to_date-1).sum(:quantity)

    entrances - exits
  end

  def self.consumption_balance(unity_id, material_id)
    entrances = ***REMOVED***_consumption(unity_id, material_id).map(&:quantity).sum(:quantity)
    entrances = 0 if entrances.eql?(:quantity)
    exits = ***REMOVED***_consumption(unity_id, material_id).sum(:quantity)

    entrances - exits
  end

  def self.***REMOVED***(unity_id, material_id, start_date, end_date)
    entrances = ***REMOVED***.by_material_id(material_id)
                                    .by_unity_id(unity_id)
                                    .in_period(start_date, end_date)
    entrances.joins(%Q(
      INNER JOIN ***REMOVED*** AS me
              ON material_entrance_items.material_entrance_id = me.id
      INNER JOIN ***REMOVED*** AS m
              ON material_entrance_items.material_id = m.id
             AND m.active
      INNER JOIN ***REMOVED*** AS mu
              ON mu.id = material_entrance_items.measuring_unit_id
      INNER JOIN ***REMOVED*** AS mu_base
              ON mu_base.id = m.measuring_unit_id
      INNER JOIN units_conversions AS uc
              ON uc.measuring_unit_id = mu.id
             AND uc.unit = mu.unit
      INNER JOIN units_conversions AS uc_base
              ON uc_base.measuring_unit_id = mu_base.id
             AND uc_base.unit = mu_base.unit,
        LATERAL (SELECT CASE uc.calc
                            WHEN 'm' THEN (material_entrance_items.quantity * uc.quantity)
                            WHEN 'd' THEN (material_entrance_items.quantity / uc.quantity)
                        END AS quantity
                ) AS td_conversion,
        LATERAL (SELECT CASE uc_base.calc
                            WHEN 'm' THEN (td_conversion.quantity / uc_base.quantity)
                            WHEN 'd' THEN (td_conversion.quantity * uc_base.quantity)
                        END AS quantity
                ) AS td_conversion_base
    )).select(%Q(
      me.entered_at AS date,
      'Entrada' AS movement_type,
      td_conversion_base.quantity AS quantity
    ))
  end

  def self.***REMOVED***(unity_id, material_id, start_date, end_date)
    exits = ***REMOVED***.by_material_id(material_id)
                            .by_unity_id(unity_id)
                            .in_period(start_date, end_date)
    exits.joins(%Q(
      INNER JOIN ***REMOVED*** AS me
              ON material_exit_items.material_exit_id = me.id
      INNER JOIN ***REMOVED*** AS m
              ON material_exit_items.material_id = m.id
             AND m.active
      INNER JOIN ***REMOVED*** AS mu
              ON mu.id = m.consumption_unit_id
      INNER JOIN ***REMOVED*** AS mu_base
              ON mu_base.id = m.measuring_unit_id
      INNER JOIN units_conversions AS uc
              ON uc.measuring_unit_id = mu.id
             AND uc.unit = mu.unit
      INNER JOIN units_conversions AS uc_base
              ON uc_base.measuring_unit_id = mu_base.id
             AND uc_base.unit = mu_base.unit,
        LATERAL (SELECT CASE uc.calc
                            WHEN 'm' THEN (material_exit_items.quantity * uc.quantity)
                            WHEN 'd' THEN (material_exit_items.quantity / uc.quantity)
                        END AS quantity
                ) AS td_conversion,
        LATERAL (SELECT CASE uc_base.calc
                            WHEN 'm' THEN (td_conversion.quantity / uc_base.quantity)
                            WHEN 'd' THEN (td_conversion.quantity * uc_base.quantity)
                        END AS quantity
                ) AS td_conversion_base
    )).select(%Q(
      me.exited_at AS date,
      'Saída' AS movement_type,
      td_conversion_base.quantity AS quantity
    ))
  end

  def self.***REMOVED***_consumption(unity_id, material_id)
    entrances = ***REMOVED***.by_material_id(material_id)
                                    .by_unity_id(unity_id)
    entrances.joins(%Q(
      INNER JOIN ***REMOVED*** AS me
              ON material_entrance_items.material_entrance_id = me.id
      INNER JOIN ***REMOVED*** AS m
              ON material_entrance_items.material_id = m.id
             AND m.active
      INNER JOIN ***REMOVED*** AS mu
              ON mu.id = material_entrance_items.measuring_unit_id
      INNER JOIN ***REMOVED*** AS mu_base
              ON mu_base.id = m.consumption_unit_id
      INNER JOIN units_conversions AS uc
              ON uc.measuring_unit_id = mu.id
            AND uc.unit = mu.unit
      INNER JOIN units_conversions AS uc_base
              ON uc_base.measuring_unit_id = mu_base.id
            AND uc_base.unit = mu_base.unit,
        LATERAL (SELECT CASE uc.calc
                            WHEN 'm' THEN (material_entrance_items.quantity * uc.quantity)
                            WHEN 'd' THEN (material_entrance_items.quantity / uc.quantity)
                        END AS quantity
                ) AS td_conversion,
        LATERAL (SELECT CASE uc_base.calc
                            WHEN 'm' THEN (td_conversion.quantity / uc_base.quantity)
                            WHEN 'd' THEN (td_conversion.quantity * uc_base.quantity)
                        END AS quantity
                ) AS td_conversion_base
    )).select(%Q(
      SUM(COALESCE(td_conversion_base.quantity, 0)) AS quantity
    ))
  end

  def self.***REMOVED***_consumption(unity_id, material_id)
    exits = ***REMOVED***.by_material_id(material_id)
                            .by_unity_id(unity_id)
    exits.joins(%Q(
      INNER JOIN ***REMOVED*** AS me
              ON material_exit_items.material_exit_id = me.id
    )).select(%Q(
      SUM(material_exit_items.quantity) AS quantity
    ))
  end
end
