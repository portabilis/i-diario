# frozen_string_literal: true

class DisciplineRecordDeletionStatus < EnumerateIt::Base
  associate_values :processing, :completed, :error
end
