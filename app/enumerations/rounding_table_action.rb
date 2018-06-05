class RoundingTableAction < EnumerateIt::Base
  associate_values(
    none: 0,
    below: 1,
    above: 2,
    specific: 3
  )

  sort_by :value
end
