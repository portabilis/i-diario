class EntityLogoUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # O brasão aparece com 60 px de altura na tela e com cerca de 50 pt nos PDFs:
  # 400 px cobre telas de alta densidade e a impressão sem guardar a resolução original.
  MAX_DIMENSION = 400
  WEBP_QUALITY = 85
  OPTIMIZED_EXTENSION = 'webp'.freeze

  process optimize: OPTIMIZED_EXTENSION

  # Prawn só lê PNG e JPEG, e o PNG preserva a transparência que o JPEG perderia.
  version :pdf do
    process optimize: 'png'

    def full_filename(for_file)
      super(for_file).sub(/\.#{OPTIMIZED_EXTENSION}\z/, '.png')
    end
  end

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def extension_whitelist
    %w[jpg jpeg gif png webp]
  end

  # O nome muda a cada envio para que a URL do brasão possa ficar em cache no navegador
  # sem risco de servir a imagem anterior.
  def filename
    return if original_filename.blank?

    "#{File.basename(original_filename, '.*')}-#{secure_token}.#{OPTIMIZED_EXTENSION}"
  end

  def self.optimized_identifier?(identifier)
    File.extname(identifier.to_s) == ".#{OPTIMIZED_EXTENSION}"
  end

  # Brasão gravado antes da otimização não tem a versão PDF; nesse caso o próprio arquivo
  # original, que é PNG, JPEG ou GIF, é o que os relatórios usam.
  def optimized?
    self.class.optimized_identifier?(identifier)
  end

  def for_pdf
    optimized? ? pdf : self
  end

  private

  # page: 0 fica só com o primeiro quadro de GIF animado; o loader do image_processing
  # também corrige a orientação EXIF de fotos.
  def optimize(format)
    minimagick! do |builder|
      builder
        .loader(page: 0)
        .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
        .colorspace('sRGB')
        .strip
        .saver(quality: WEBP_QUALITY)
        .convert(format)
    end
  end

  def secure_token
    token = :"@#{mounted_as}_secure_token"
    model.instance_variable_get(token) || model.instance_variable_set(token, SecureRandom.hex(8))
  end
end
