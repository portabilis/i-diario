class InfrequencyTrackingTypes < EnumerateIt::Base
  associate_values :consecutive_absences,
                   :alternating_absences
end
