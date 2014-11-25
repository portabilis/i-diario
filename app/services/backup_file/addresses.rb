class BackupFile
  class Addresses < Base
    def filename
      "enderecos.csv"
    end

    protected

    def query
      Address
    end
  end
end
