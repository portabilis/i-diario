# Grava os brasões num diretório temporário, e não em public/uploads, e gera
# imagens de teste com o ImageMagick que o uploader usa.
RSpec.shared_context 'entity logo storage' do
  around do |example|
    original_root = EntityLogoUploader.root
    storage_root = Dir.mktmpdir('entity_logo')
    EntityLogoUploader.root = storage_root

    begin
      example.run
    ensure
      EntityLogoUploader.root = original_root
      FileUtils.rm_rf(storage_root)
      FileUtils.rm_rf(@logo_source_dir) if @logo_source_dir
    end
  end

  def build_logo_image(file_name, size: '1600x1200', source: 'gradient:red-blue', frames: 1)
    path = File.join(logo_source_dir, file_name)

    MiniMagick::Tool::Convert.new do |convert|
      convert.size(size)
      frames.times { convert << source }
      convert << path
    end

    path
  end

  def logo_source_dir
    @logo_source_dir ||= Dir.mktmpdir('entity_logo_source')
  end

  # Fundo transparente com um círculo opaco no meio, como um brasão recortado.
  def build_transparent_logo_image(file_name, size: '1600x1200')
    width, height = size.split('x').map(&:to_i)
    path = File.join(logo_source_dir, file_name)

    MiniMagick::Tool::Convert.new do |convert|
      convert.size(size)
      convert << 'xc:none'
      convert.fill('red')
      convert.draw("circle #{width / 2},#{height / 2} #{width / 2},#{height / 4}")
      convert << path
    end

    path
  end
end
