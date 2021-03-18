class BackupStatus < EnumerateIt::Base
  associate_values :started, :error, :completed
end
