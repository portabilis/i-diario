class RoundingTableAction < EnumerateIt::Base
  associate_values :none, :below, :above, :specific

  private

  def self.values
    { none: 0, below: 1, above: 2, specific: 3 }
  end
end
