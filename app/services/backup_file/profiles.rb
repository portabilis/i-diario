class BackupFile
  class Profiles < Base
    def filename
      "perfis.csv"
    end

    protected

    def query
      Profile
    end
  end
end
