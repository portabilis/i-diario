class EventTypes < EnumerateIt::Base
  associate_values(
    :extra_school, 
    :extra_school_without_frequency,
    :no_school,
    :no_school_with_frequency
  )

  sort_by :translation
end
