class ApiSynchronizationStatus < EnumerateIt::Base
  associate_values :started, :error, :completed, :warning
end
