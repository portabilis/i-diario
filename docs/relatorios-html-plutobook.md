# Relatórios HTML → PDF: motor PlutoBook (driver `pluto`)

O i-Diário gera PDF enviando HTML para o serviço de renderização (URL em `report_html_url`, nos secrets) através do `ReportGenerator`. O serviço oferece mais de um motor; o i-Diário usa dois:

| driver | quando usar |
|---|---|
| `pluto` (PlutoBook) | **relatório novo** e alvo da migração dos existentes |
| `chrome` | default do `ReportGenerator`; só para os relatórios ainda não migrados |

O default do método continua `:chrome`, então `driver: :pluto` é sempre explícito na chamada.

## Estado atual dos relatórios HTML

| relatório | controller | layout | driver |
|---|---|---|---|
| Registro de Frequência por aluno | `attendance_record_report_by_students_controller.rb` | `report_pluto` | `pluto` |
| Quadro de Aulas | `lessons_boards_controller.rb` | `report_pluto` | `pluto` |
| PEI (plano e versões) | `concerns/renders_iep_pdf.rb` | `pdf_individualized_educational_plan` | `chrome` |

## Ganho medido

Medições numa rede com volume de dados, 5 execuções por cenário, **mesmo HTML enviado aos dois motores** — a única variável é o motor. O valor é a mediana; o serviço tem outliers ocasionais de ~4s que a mediana absorve.

| relatório | HTML | chrome | pluto | PDF chrome | PDF pluto |
|---|---|---|---|---|---|
| Frequência, 1 turma | 16 KB | 1,01s | **0,50s** | 120 KB | **46 KB** |
| Frequência, unidade toda (78 turmas) | 239 KB | 3,01s | **1,38s** | 1.771 KB | **183 KB** |
| Quadro de Aulas | 9 KB | 0,92s | **0,46s** | 62 KB | **35 KB** |
| PEI (ainda no chrome) | 6 KB | 0,95s | **0,44s** | 59 KB | **42 KB** |

O pluto fica em torno de 2x mais rápido em todos os cenários, e a diferença de tamanho do PDF cresce com o volume: no relatório de unidade inteira o arquivo cai de 1,7 MB para 183 KB.

O serviço tem falhas transientes — durante as medições alguns POSTs devolveram `OpenTimeout` e a repetição imediata passou. O `ReportGenerator` hoje não tem retry.

**O chrome emite em `letter` (612×792pt), papel americano.** O `report_pluto` declara `size: A4 portrait`.

## Como chamar

```ruby
html_content = render_to_string(action: :report, layout: 'report_pluto')

response = ReportGenerator.call(html_content, driver: :pluto)
```

O `ReportGenerator` comprime o corpo com gzip automaticamente acima de `GZIP_THRESHOLD_BYTES` (1 MB). Não há nada a configurar por relatório.

## Layout `report_pluto`

Use `app/views/layouts/report_pluto.html.erb`. Ele resolve cabeçalho, numeração de página e margens; o relatório entrega só o conteúdo.

O cabeçalho é o mesmo dos demais relatórios do i-Diário: o **título do relatório** sobre o **brasão** e a identificação da rede — apenas `entity_name` e `organ_name` do `current_entity_configuration`. O título vem do relatório, pelo `content_for :report_title`; o resto o layout resolve sozinho.

```erb
<% content_for :report_title, 'Registro de Frequência por aluno' %>
```

**O relatório não deve repetir esses dados na própria view** — sai duplicado no PDF. Não acrescente endereço, telefone ou e-mail: não é o que os relatórios daqui identificam.

O rodapé traz só "Página N de M", como margin box do `@page`. No pluto a numeração é responsabilidade do CSS da view, não de parâmetro da requisição:

```css
@page {
  size: A4 portrait;
  margin: 12mm 10mm 16mm 10mm;
  @bottom-right { content: "Página " counter(page) " de " counter(pages); vertical-align: top; padding-top: 4.2mm; }
}
```

**A margem inferior precisa comportar a numeração inteira**: o pluto não empurra o conteúdo para abrir espaço, e o que não couber vira sobreposição silenciosa. A validação tem de ser numa página **cheia** — página com sobra de espaço não exercita o encontro entre a última linha e a numeração.

### Estilo próprio do relatório

O relatório declara o que é dele no `content_for :head`, que o layout injeta depois do CSS base. O Quadro de Aulas é o exemplo: o `report_pluto` deixa `th` sem cor de fundo, e aquele relatório distingue cabeçalho de conteúdo por ela.

```erb
<% content_for :report_title, 'Quadro de Aulas' %>

<% content_for :head do %>
  <style>
    .lessons-table th { background-color: #DEDEDE; }
  </style>
<% end %>
```

Regra de `table`, `th` ou `td` declarada pelo relatório alcança também a tabela do cabeçalho do layout. O layout pina a posição e o corpo de fonte do cabeçalho por classe para ele sair igual em todos os relatórios; não sobrescreva `.report-header`.

## Armadilhas do motor

Todas observadas nos relatórios daqui, não deduzidas.

**O pluto não encolhe a página.** O chrome reduz o documento inteiro até o conteúdo caber, mascarando elementos largos demais e imprimindo a fonte menor do que o CSS declara. No pluto, o que excede a largura útil (190mm com as margens do `report_pluto`) vaza para fora do papel, e a fonte sai no tamanho declarado. Ao migrar um layout que estourava a área imprimível, **calibre pelo tamanho impresso no PDF antigo, não pelo CSS antigo** — o Quadro de Aulas declarava 12px e imprimia 11,2px (fator 0,935, medido com `pdftotext -bbox` na mesma palavra nos dois PDFs).

**Não repita o cabeçalho de tabela (`thead`) entre páginas.** O `report_pluto` declara `display: table-row-group`, e o relatório não deve voltar para `table-header-group`: o cabeçalho sai só no início da tabela. Com a repetição ligada, o pluto:

- ignora `break-inside` e `break-after` em `thead` e `tr` — nenhuma regra de quebra em linha de tabela tem efeito;
- quando a tabela começa empurrada para a página nova, desenha o cabeçalho duas vezes, com a segunda cópia por cima das primeiras linhas.

**O pluto quebra página entre quaisquer linhas de tabela**, com ou sem repetição. Linhas que precisam sair juntas (como Série e Turma no Registro de Frequência) vão numa **única célula**, empilhadas em `div` — o pluto não quebra dentro de uma linha. `break-inside: avoid` só tem efeito em bloco: envolver a tabela num `div` evita a quebra, mas empurra a tabela inteira para a página seguinte sempre que ela não cabe no espaço restante, e uma tabela maior que o espaço abaixo do cabeçalho deixa a primeira página praticamente vazia.

**O pluto não converte JPEG CMYK.** A imagem sai com as cores trocadas, sem erro nem aviso; o chrome converte e mascara o problema. `EntityConfiguration#logo_base64_data_uri` repassa os bytes originais do brasão, sem normalizar o colorspace, e o `EntityLogoUploader` aceita JPEG — um brasão CMYK sai errado no pluto. É lacuna conhecida, a corrigir em `EntityConfiguration#fetch_logo_data` (normalizar para sRGB; o `mini_magick` já está no `Gemfile.lock`).

## Conferir o motor de um PDF

```bash
pdfinfo arquivo.pdf | grep Creator   # pluto → Creator: PlutoBook
```

## Medir um relatório

Para comparar os motores, **renderize o HTML uma vez e envie o mesmo conteúdo aos dois** — assim a única variável é o motor:

1. Instancie o controller fora do ciclo de request e injete as ivars que a view consome. Sete `@current_entity` direto: o `current_entity` resolve o tenant por `request.host`, e a tabela `entities` não existe na conexão aberta pelo `using_connection`.
2. Chame `render_to_string(action:, layout: 'report_pluto', formats: [:html])` uma vez e guarde o HTML.
3. Passe esse mesmo HTML por `ReportGenerator.call(html, driver: :chrome)` e `driver: :pluto`, cronometrando cada chamada e repetindo ao menos 5 vezes. **Use a mediana.**
4. Grave os PDFs em `tmp/` e confira:

```bash
pdfinfo tmp/saida.pdf                              # páginas, tamanho da folha, motor
pdftoppm -png -r 80 -f 1 -l 1 tmp/saida.pdf pagina # inspeção visual
pdftotext -bbox -f 1 -l 1 tmp/saida.pdf saida.xml  # largura de palavra, para comparar métrica
```

Confira a **segunda** página e as quebras entre turmas/registros, não só a primeira — é onde o motor diverge. E valide em mais de uma rede e unidade: uma amostra só esconde quebra que cai em lugar diferente com outro volume.
