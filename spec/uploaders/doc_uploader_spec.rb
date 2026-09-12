require 'rails_helper'

# CVE-2025-7870 / GHSA-38rj-9g42-pxrv — defesa em profundidade.
# A extensão .svg já é barrada por extension_whitelist. Aqui se garante também que conteúdo que o
# navegador executa (SVG/HTML) seja rejeitado pelo content-type, mesmo com extensão permitida.
RSpec.describe DocUploader do
  subject(:uploader) { described_class.new(AbsenceJustificationAttachment.new, :attachment) }

  def upload(basename, content, declared_type)
    file = Tempfile.new(['upload', File.extname(basename)])
    file.binmode
    file.write(content)
    file.rewind
    uploader.cache!(Rack::Test::UploadedFile.new(file.path, declared_type, original_filename: basename))
  ensure
    file.close
  end

  it 'rejects an .svg file (extension)' do
    expect do
      upload('evil.svg', '<svg><script>alert(1)</script></svg>', 'image/svg+xml')
    end.to raise_error(CarrierWave::IntegrityError)
  end

  it 'rejects an allowed extension declaring an svg content-type' do
    expect do
      upload('evil.xml', '<svg><script>alert(1)</script></svg>', 'image/svg+xml')
    end.to raise_error(CarrierWave::IntegrityError)
  end

  it 'rejects a file declaring an html content-type' do
    expect do
      upload('evil.xml', '<html><script>alert(1)</script></html>', 'text/html')
    end.to raise_error(CarrierWave::IntegrityError)
  end

  it 'accepts a legitimate png' do
    expect do
      upload('ok.png', "\x89PNG\r\n\x1a\n#{"\x00" * 32}", 'image/png')
    end.not_to raise_error

    expect(uploader.file).to be_present
  end

  it 'accepts a legitimate pdf' do
    expect do
      upload('ok.pdf', "%PDF-1.4\n%\xe2\xe3\n", 'application/pdf')
    end.not_to raise_error
  end
end
