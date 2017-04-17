class BackupFile
  class DisciplineContentRecords < Base
    def filename
      "registros_de_conteudo_por_disciplina.csv"
    end

    protected

    def query
      DisciplineContentRecord
    end
  end
end
