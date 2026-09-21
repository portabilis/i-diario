# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportGenerator, type: :service do
  let(:report_url) { Rails.application.secrets.report_html_url }
  let(:secret_key) { Rails.application.secrets.report_html_secret_key }
  let(:executed_requests) { [] }

  # Corpo pequeno: abaixo do limiar, a requisição tem de sair exatamente como
  # antes da compressão existir (form-encoded, sem headers de codificação).
  let(:small_html) { '<html><body>Relatório</body></html>' }

  # O limiar mede o corpo serializado em JSON, não o HTML. Este HTML já estoura
  # 1 MB sozinho, então o corpo serializado também estoura.
  let(:large_html) { "<html><body>#{'a' * 1.megabyte}</body></html>" }

  before do
    allow(RestClient::Request).to receive(:execute) do |args|
      executed_requests << args
      double(body: '%PDF-fake')
    end
  end

  describe '.call' do
    context 'when the serialized body is below the gzip threshold' do
      it 'sends the params hash form-encoded without encoding headers' do
        described_class.call(small_html)

        expect(executed_requests.size).to eq(1)
        expect(executed_requests.first).to eq(
          method: :post,
          url: report_url,
          payload: { html: small_html, driver: :chrome },
          headers: { Authorization: "Bearer #{secret_key}" },
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT
        )
      end

      it 'forwards the requested driver' do
        described_class.call(small_html, driver: :pluto)

        expect(executed_requests.first[:payload]).to eq(html: small_html, driver: :pluto)
      end
    end

    context 'when the serialized body is above the gzip threshold' do
      before { described_class.call(large_html, driver: :pluto) }

      # O serviço devolve 400 se o header vier sem o corpo comprimido, ou o
      # inverso: os dois andam sempre juntos.
      it 'sends the gzip encoding headers alongside the compressed body' do
        expect(executed_requests.first[:headers]).to eq(
          content_type: :json,
          'Content-Encoding' => 'gzip',
          Authorization: "Bearer #{secret_key}"
        )
      end

      it 'compresses the same params the uncompressed path would send' do
        body = ActiveSupport::Gzip.decompress(executed_requests.first[:payload])

        expect(JSON.parse(body)).to eq('html' => large_html, 'driver' => 'pluto')
      end

      it 'keeps the timeouts of the uncompressed path' do
        expect(executed_requests.first).to include(
          method: :post,
          url: report_url,
          open_timeout: described_class::OPEN_TIMEOUT,
          read_timeout: described_class::READ_TIMEOUT
        )
      end
    end

    context 'when the serialized body sits exactly on the threshold' do
      # O limiar é exclusivo (`<`): corpo do tamanho exato já vai comprimido.
      it 'compresses the body' do
        threshold = { html: small_html, driver: :chrome }.to_json.bytesize
        stub_const("#{described_class}::GZIP_THRESHOLD_BYTES", threshold)

        described_class.call(small_html)

        body = ActiveSupport::Gzip.decompress(executed_requests.first[:payload])

        expect(JSON.parse(body)).to eq('html' => small_html, 'driver' => 'chrome')
      end
    end
  end
end
