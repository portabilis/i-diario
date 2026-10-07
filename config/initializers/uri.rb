# A gem `uri` (>= 1.0) entra no bundle como dependência da `net-http` e remove
# `URI.escape`. Este no-op mantém o route_translator de pé — o preço é que
# segmentos de rota traduzidos passam sem escape.
# Tirar a `net-http` do Gemfile devolve a stdlib do Ruby 2.7, e aí este arquivo
# passa a sobrescrever um `URI.escape` que funciona: os dois andam juntos.
module URI
  def URI.escape(url)
    url
  end
end
