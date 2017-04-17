class BackupFile
  class TestSettingTests < Base
    def filename
      "avaliacoes_de_configuracao_de_avaliacao.csv"
    end

    protected

    def query
      TestSettingTest
    end
  end
end
