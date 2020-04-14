class ComparativeOperators < EnumerateIt::Base
  associate_values :equals,
                   :greater_than,
                   :less_than,
                   :greater_than_or_equal_to,
                   :less_than_or_equal_to
end
