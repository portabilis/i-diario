# frozen_string_literal: true

require 'rails_helper'
require 'net/http'

# O VCR roda sem gravação: requisição sem interação no cassete levanta
# VCR::Errors::UnhandledHTTPRequestError em vez de ir para a rede e ser anexada ao .yml
# na ejeção do cassete. Com o modo de gravação ligado, a execução da suíte escreve em
# spec/cassettes e deixa a árvore suja pelo que o teste gravou.
RSpec.describe 'VCR recording mode' do
  cassette_name = 'unmatched_request_probe'
  cassette_path = Rails.root.join('spec/cassettes', "#{cassette_name}.yml")

  it 'raises for a request with no recorded interaction instead of going to the network' do
    expect do
      VCR.use_cassette(cassette_name) do
        # A porta 1 recusa a conexão: com a gravação ligada a requisição real falha por
        # ECONNREFUSED no lugar do erro do VCR, e nada é gravado.
        Net::HTTP.get_response(URI('http://127.0.0.1:1/'))
      end
    end.to raise_error(VCR::Errors::UnhandledHTTPRequestError)

    expect(cassette_path).not_to exist
  end
end
