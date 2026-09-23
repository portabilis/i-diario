require 'rails_helper'

RSpec.describe EntityLogoUploader, type: :model do
  include_context 'entity logo storage'

  let(:entity_configuration) { EntityConfiguration.create! }

  def upload(path)
    File.open(path) do |file|
      entity_configuration.update!(logo: file)
    end

    entity_configuration.reload.logo
  end

  def image_of(uploader)
    MiniMagick::Image.open(uploader.path)
  end

  context 'when the logo is larger than the limit' do
    subject(:logo) { upload(build_logo_image('brasao.png')) }

    it 'stores a WebP that fits the limit keeping the aspect ratio' do
      image = image_of(logo)

      expect(image.type).to eq('WEBP')
      expect(image.dimensions).to eq([400, 300])
    end

    it 'keeps the original name in the stored file name' do
      expect(logo.identifier).to match(/\Abrasao-\h{16}\.webp\z/)
    end

    it 'stores a PNG of the same size for the PDFs' do
      image = image_of(logo.pdf)

      expect(image.type).to eq('PNG')
      expect(image.dimensions).to eq([400, 300])
      expect(File.basename(logo.pdf.path)).to eq("pdf_#{logo.identifier.sub(/\.webp\z/, '.png')}")
    end
  end

  it 'does not enlarge a logo smaller than the limit' do
    logo = upload(build_logo_image('brasao.png', size: '120x90'))

    expect(image_of(logo).dimensions).to eq([120, 90])
    expect(image_of(logo.pdf).dimensions).to eq([120, 90])
  end

  it 'stores a JPEG as a much smaller WebP' do
    source = build_logo_image('brasao.jpg')
    logo = upload(source)

    expect(image_of(logo).type).to eq('WEBP')
    expect(File.size(logo.path)).to be < File.size(source) / 5
  end

  it 'keeps the transparency of the logo in both files' do
    logo = upload(build_transparent_logo_image('brasao.png'))

    [logo, logo.pdf].each do |file|
      corner_alpha = MiniMagick::Tool::Convert.new do |convert|
        convert << file.path
        convert.format('%[fx:p{0,0}.a]')
        convert << 'info:'
      end

      expect(corner_alpha.strip).to eq('0')
    end
  end

  it 'keeps only the first frame of an animated GIF' do
    logo = upload(build_logo_image('brasao.gif', size: '800x600', source: 'xc:red', frames: 3))

    expect(image_of(logo).layers.size).to eq(1)
    expect(image_of(logo.pdf).layers.size).to eq(1)
  end

  it 'gives each upload a new file name so the browser cache never serves the previous one' do
    source = build_logo_image('brasao.png')
    first_identifier = upload(source).identifier

    entity_configuration.instance_variable_set(:@logo_secure_token, nil)
    second_identifier = upload(source).identifier

    expect(second_identifier).not_to eq(first_identifier)
  end

  it 'rejects files that are not images' do
    path = File.join(logo_source_dir, 'brasao.pdf')
    File.write(path, '%PDF-1.4')

    File.open(path) { |file| entity_configuration.logo = file }

    expect(entity_configuration).not_to be_valid
    expect(entity_configuration.errors[:logo]).to be_present
  end

  describe '#for_pdf' do
    it 'returns the PNG version of an optimized logo' do
      logo = upload(build_logo_image('brasao.png'))

      expect(logo).to be_optimized
      expect(logo.for_pdf).to eq(logo.pdf)
    end

    it 'returns the logo itself when it was stored before the optimization' do
      entity_configuration.update_column(:logo, 'brasao.png')
      logo = entity_configuration.reload.logo

      expect(logo).not_to be_optimized
      expect(logo.for_pdf).to equal(logo)
    end
  end
end
