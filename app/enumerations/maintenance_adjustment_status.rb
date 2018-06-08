class MaintenanceAdjustmentStatus < EnumerateIt::Base
  associate_values :completed, :in_progress, :pending, :error
end
