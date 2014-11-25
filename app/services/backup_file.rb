class BackupFile
  def self.process!
    new.process!
  end

  def process!
    Zip::OutputStream.open(tempfile.path) do |zip|
      files.each do |file|
        zip.put_next_entry file.filename
        zip.print file.to_csv
      end
    end

    tempfile
  end

  protected

  def tempfile
    @tempfile ||= Tempfile.new([filename, ".zip"])
  end

  def filename
    "backup-#{DateTime.current}"
  end

  def files
    @files ||= [
      BackupFile::Addresses.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***Menus.new,
      BackupFile::GeneralConfigurations.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***Requests.new,
      BackupFile::***REMOVED***RequestItems.new,
      BackupFile::***REMOVED***RequestAuthorizations.new,
      BackupFile::***REMOVED***RequestAuthorizationItems.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Menus.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::***REMOVED***Unities.new,
      BackupFile::Menu***REMOVED***s.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Notifications.new,
      BackupFile::Profiles.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Stock***REMOVED***.new,
      BackupFile::Students.new,
      BackupFile::***REMOVED***s.new,
      BackupFile::Unities.new,
      BackupFile::Users.new
    ]
  end
end
