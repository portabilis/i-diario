class BackupFile
  class AbsenceJustifications < Base
    def filename
      "justificativas_de_falta.csv"
    end

    protected

    def query
      AbsenceJustification
    end
  end
end
