class BackupFile
  class TransferNotes < Base
    def filename
      "notas_de_transferencia.csv"
    end

    protected

    def query
      TransferNote
    end
  end
end
