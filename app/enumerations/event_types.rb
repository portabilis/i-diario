class EventTypes < EnumerateIt::Base
  associate_values :no_school, :extra_school, :extra_school_without_frequency

  sort_by :none
end
