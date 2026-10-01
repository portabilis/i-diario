require 'rails_helper'
require 'ejs'

# Advisories refletidos GHSA-jwmm-26cg-qmx9, GHSA-x7fw-qx4x-5p39, GHSA-fg9r-g596-752p,
# GHSA-hpj6-p39r-vggp, GHSA-23q9-82wh-jpwv (+ variantes refletidas de CVE-2025-7871/GHSA-v7cm).
# Os campos "Adicionar Conteúdos/Objetivos" (select2 tags) inserem o texto digitado no DOM via
# template EJS. O texto do usuário deve sair pela tag de escape do EJS (<%- %>), não pela de
# interpolação (<%= %>). Avalia o template com o mesmo compilador (gem ejs) usado pelo sprockets.
{
  'contents' => Rails.root.join('app/assets/javascripts/templates/layouts/contents_list_manual_item.jst.ejs'),
  'objectives' => Rails.root.join('app/assets/javascripts/templates/layouts/objectives_list_manual_item.jst.ejs')
}.each do |label, template_path|
  RSpec.describe "#{label} tag template" do
    def render_template(path, description)
      EJS.evaluate(
        File.read(path),
        'id' => 'customId_1',
        'description' => description,
        'model_name' => 'discipline_record',
        'submodel_name' => 'record'
      )
    end

    it 'escapes an <img onerror> payload in every position' do
      out = render_template(template_path, '<img src=x onerror=alert(1)>')

      expect(out).not_to include('<img src=x onerror=alert(1)>')
      expect(out).to include('&lt;img')
    end

    it 'escapes a <script> payload' do
      out = render_template(template_path, '<script>alert(1)</script>')

      expect(out).not_to include('<script>alert(1)</script>')
    end
  end
end
