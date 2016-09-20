class DailyNoteStatuses < EnumerateIt::Base
  associate_values :incomplete, :complete
end
