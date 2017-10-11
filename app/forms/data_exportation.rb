class DataExportation
  include ActiveModel::Model

  def current
    GeneralConfiguration.current
  end
end
