require 'rails_helper'

# XSS armazenado disparado na página de Histórico (registros auditados). Os valores auditados de
# texto livre e de campos rich-text são renderizados com `raw` nas parciais de histórico, então a
# neutralização precisa acontecer aqui, no ponto de leitura.
#
# CVE-2025-7872, CVE-2025-8511, CVE-2025-8786, CVE-2025-8787, CVE-2025-8788,
# CVE-2025-9104, CVE-2025-9105, CVE-2025-9106, CVE-2025-8919
RSpec.describe AuditDecorator, type: :decorator do
  subject(:decorator) { described_class.new(audit) }

  # ObservationDiaryRecordNote tem um campo de texto livre (`description`) e não é enumeração nem
  # associação, então cai no ramo de sanitização.
  let(:audit) { double('Audited::Audit', auditable_type: 'ObservationDiaryRecordNote') }

  def parse_new_value(value)
    decorator.parse(:description, ['valor antigo', value], :last)
  end

  describe '#parse of free-text fields' do
    it 'strips <script> keeping the text content' do
      output = parse_new_value('<script>alert(1)</script>')

      expect(output).not_to include('<script>')
      expect(output).to include('alert(1)')
    end

    it 'neutralizes an <img onerror> payload' do
      output = parse_new_value('"><img src=x onerror=alert(1)>')

      expect(output).not_to include('<img')
      expect(output).not_to include('onerror')
    end

    it 'is resistant to case variation in the script tag' do
      output = parse_new_value('<ScRipT>alert(1)</ScRipT>')

      expect(output.downcase).not_to include('<script>')
    end

    it 'preserves the basic formatting produced by the editor' do
      value = 'com <b>negrito</b>, <i>itálico</i> e <u>sublinhado</u>'

      expect(parse_new_value(value)).to eq(value)
    end

    it 'returns content flagged as html_safe' do
      expect(parse_new_value('texto simples')).to be_html_safe
    end
  end
end
