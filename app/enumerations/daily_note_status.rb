class DailyNoteStatus < EnumerateIt::Base
  associate_values :incomplete, :complete
end
