class BackupTypes < EnumerateIt::Base
  associate_values :full_system_backup, :school_calendar_backup, :unique_school_days_backup
end
