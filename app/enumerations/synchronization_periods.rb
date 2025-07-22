class SynchronizationPeriods < EnumerateIt::Base
  associate_values :current_year,
                   :last_two_years
end