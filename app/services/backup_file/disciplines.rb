class BackupFile
  class Disciplines < Base
    def filename
      "disciplinas.csv"
    end

    protected

    def query
      Discipline
    end
  end
end
