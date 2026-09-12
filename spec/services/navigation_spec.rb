require 'rails_helper'

# CVE-2025-8920 / GHSA-v2qp-2w8g-3363
# Os termos do "Dicionário de Termos BNCC" são valores de Translation editáveis pelo usuário e
# viram o título/breadcrumb das telas de planos de ensino. Título e breadcrumb eram montados com
# `raw`, então HTML nesses termos executava ao abrir a tela. Devem escapar o texto e manter o ícone.
RSpec.describe Navigation, type: :service do
  let(:payload) { '<img src=x onerror=alert(1)>' }

  before do
    allow(Translator).to receive(:translate).and_return("Planos #{payload}")
  end

  describe '.draw_title' do
    subject(:html) { described_class.draw_title('discipline_teaching_plans', true, nil).to_s }

    it 'escapes the translated title text' do
      expect(html).to include('&lt;img src=x onerror=alert(1)&gt;')
      expect(html).not_to include(payload)
    end

    it 'keeps the icon markup intact' do
      expect(html).to include('<i class=')
    end
  end

  describe '.draw_breadcrumbs' do
    subject(:html) { described_class.draw_breadcrumbs('discipline_teaching_plans', nil).to_s }

    it 'escapes the translated breadcrumb text' do
      expect(html).to include('&lt;img')
      expect(html).not_to include(payload)
    end
  end
end
