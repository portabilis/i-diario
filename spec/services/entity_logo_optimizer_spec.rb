require 'rails_helper'

RSpec.describe EntityLogoOptimizer, type: :service do
  include_context 'entity logo storage'

  let(:entity_configuration) { EntityConfiguration.create! }

  # Grava o brasão como era gravado antes da otimização: o arquivo enviado, sem versões.
  def store_legacy_logo(source)
    directory = File.join(EntityLogoUploader.root, entity_configuration.logo.store_dir)
    FileUtils.mkdir_p(directory)
    FileUtils.cp(source, File.join(directory, File.basename(source)))
    entity_configuration.update_column(:logo, File.basename(source))
    entity_configuration.reload
  end

  it 'stores a legacy logo again as a resized WebP with the PNG version for the PDFs' do
    store_legacy_logo(build_logo_image('brasao.png'))

    result = described_class.new(entity_configuration).optimize
    logo = entity_configuration.reload.logo

    expect(result).to eq(:optimized)
    expect(logo.identifier).to match(/\Abrasao-\h{16}\.webp\z/)
    expect(MiniMagick::Image.open(logo.path).dimensions).to eq([400, 300])
    expect(MiniMagick::Image.open(logo.pdf.path).type).to eq('PNG')
  end

  it 'keeps the legacy file, which another entity may point to' do
    source = build_logo_image('brasao.png')
    store_legacy_logo(source)
    legacy_path = entity_configuration.logo.path

    described_class.new(entity_configuration).optimize

    expect(File.binread(legacy_path)).to eq(File.binread(source))
  end

  it 'reports a legacy logo whose file is not in the storage' do
    entity_configuration.update_column(:logo, 'brasao.png')

    expect(described_class.new(entity_configuration.reload).optimize).to eq(:missing_file)
  end

  it 'leaves an optimized logo untouched' do
    File.open(build_logo_image('brasao.png')) { |file| entity_configuration.update!(logo: file) }
    identifier = entity_configuration.reload.logo.identifier

    result = described_class.new(entity_configuration).optimize

    expect(result).to eq(:already_optimized)
    expect(entity_configuration.reload.logo.identifier).to eq(identifier)
  end

  it 'does nothing when the entity has no logo' do
    expect(described_class.new(entity_configuration).optimize).to eq(:without_logo)
  end

  it 'does nothing when the entity has no configuration' do
    expect(described_class.new(nil).optimize).to eq(:without_logo)
  end
end
