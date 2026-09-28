require 'tmpdir'

# Regrava pelo uploader um brasão enviado antes da otimização, para que ele passe
# pelo mesmo redimensionamento e conversão de um envio novo.
class EntityLogoOptimizer
  def initialize(entity_configuration)
    @entity_configuration = entity_configuration
  end

  def optimize
    return :without_logo if @entity_configuration.nil? || logo.identifier.blank?
    return :already_optimized if logo.optimized?
    return :missing_file unless logo.file&.exists?

    reupload

    :optimized
  end

  private

  def logo
    @entity_configuration.logo
  end

  # O arquivo temporário leva o nome original para que o novo nome e a auditoria
  # continuem identificando o brasão enviado.
  def reupload
    Dir.mktmpdir do |dir|
      path = File.join(dir, File.basename(logo.identifier))
      File.binwrite(path, logo.read)

      File.open(path) do |file|
        @entity_configuration.logo = file
        @entity_configuration.save!
      end
    end
  end
end
