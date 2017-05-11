class BackupFile
  class UnityEquipments < Base
    def filename
      "equipamentos.csv"
    end

    protected

    def query
      UnityEquipment
    end
  end
end
