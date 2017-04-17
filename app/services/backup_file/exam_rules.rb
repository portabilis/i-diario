class BackupFile
  class ExamRules < Base
    def filename
      "regras_de_avaliacao.csv"
    end

    protected

    def query
      ExamRule
    end
  end
end
