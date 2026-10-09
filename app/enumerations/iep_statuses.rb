class IepStatuses < EnumerateIt::Base
  associate_values :in_progress, :finalized
end
