class BackupFile::Base
  def file_name
    raise "Not implemented"
  end

  def to_csv
    query.copy_to_string
  end

  protected

  def query
    raise "Not implemented"
  end
end
