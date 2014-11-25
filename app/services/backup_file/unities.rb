class BackupFile
  class Unities < Base
    def filename
      "unidades.csv"
    end

    protected

    def query
      Unity
    end
  end
end
