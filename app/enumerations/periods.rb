class Periods < EnumerateIt::Base
  associate_values :matutinal, :vespertine, :nightly

  sort_by :none
end
