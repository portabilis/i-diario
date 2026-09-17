require 'rails_helper'

# CVE-2025-8920 / GHSA-v2qp-2w8g-3363
# Os termos do "Dicionário de Termos BNCC" são valores de Translation editáveis pelo usuário e
# alimentam título, breadcrumb, menu lateral e atalhos. Todo texto traduzido precisa ser escapado
# na renderização, mantendo o ícone, que é markup do próprio projeto e não do usuário.
RSpec.describe Navigation, type: :service do
  let(:payload) { '<img src=x onerror=alert(1)>' }
  let(:escaped_payload) { '&lt;img src=x onerror=alert(1)&gt;' }
  let(:current_user) { User.new(admin: true) }

  before do
    allow(Translator).to receive(:translate).and_return("Planos #{payload}")
  end

  describe '.draw_title' do
    subject(:html) { described_class.draw_title('discipline_teaching_plans', true, nil).to_s }

    it 'escapes the translated title text' do
      expect(html).to include(escaped_payload)
      expect(html).not_to include(payload)
    end

    it 'keeps the icon markup intact' do
      expect(html).to include('<i class=')
    end
  end

  describe '.draw_breadcrumbs' do
    subject(:html) { described_class.draw_breadcrumbs('discipline_teaching_plans', nil).to_s }

    it 'escapes the translated breadcrumb text' do
      expect(html).to include(escaped_payload)
      expect(html).not_to include(payload)
    end

    it 'keeps the icon markup intact' do
      expect(html).to include('<i class=')
    end
  end

  describe '.draw_menus' do
    subject(:html) { described_class.draw_menus('dashboard', current_user).to_s }

    it 'escapes the translated menu text' do
      expect(html).to include(escaped_payload)
      expect(html).not_to include(payload)
    end

    it 'keeps the icon markup intact' do
      expect(html).to include('<i class=')
    end
  end

  describe '.draw_shortcuts' do
    subject(:html) { described_class.draw_shortcuts(current_user).to_s }

    it 'escapes the translated shortcut text' do
      expect(html).to include(escaped_payload)
      expect(html).not_to include(payload)
    end

    it 'keeps the icon markup intact' do
      expect(html).to include('<i class=')
    end
  end
end
