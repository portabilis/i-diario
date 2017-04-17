class BackupFile
  class TestSettings < Base
    def filename
      "configuracoes_de_avaliacao.csv"
    end

    protected

    def query
      TestSetting
    end
  end
end
