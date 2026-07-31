# Faz cada grupo de multi-select do PEI (por "kind": comunicação, autonomia,
# tipos de suporte, acomodações...) se comportar como um campo de seleção
# múltipla comum do Rails, mesmo todos compartilhando UMA única tabela de junção.
#
# Uso no model:
#   iep_multi_select :iep_selected_options, :communication_profile, :autonomy
#
# Isso gera, para cada kind, o par de métodos que o formulário usa:
#   record.communication_profile_option_ids          # => ids das opções de comunicação marcadas
#   record.communication_profile_option_ids = [1, 2] # marca só as de comunicação
#
# São "virtuais": não há coluna com esse nome; o valor é calculado filtrando a
# tabela de junção pelo kind. O setter só mexe nas linhas daquele kind e ignora
# ids que não pertencem a ele (proteção contra injeção via params).
#
# Serve para as seções 2/3 (junção iep_selected_options) e para as acomodações
# da seção 4 (junção iep_curricular_planning_options), pois ambas têm iep_option.
module IepMultiSelectable
  extend ActiveSupport::Concern

  class_methods do
    def iep_multi_select(association, *kinds)
      kinds.each do |kind|
        define_method("#{kind}_option_ids") do
          iep_selected_option_ids_for(association, kind)
        end

        define_method("#{kind}_option_ids=") do |ids|
          assign_iep_options_for(association, kind, ids)
        end
      end
    end
  end

  private

  def iep_selected_option_ids_for(association, kind)
    kind_value = IepOptionKinds.value_of(kind)

    send(association)
      .reject(&:marked_for_destruction?)
      .select { |row| row.iep_option&.kind == kind_value }
      .map(&:iep_option_id)
  end

  def assign_iep_options_for(association, kind, ids)
    # O select2 do formulário envia os ids como string separada por vírgula (padrão
    # without_json_parser do projeto); os testes/console enviam Array. Normaliza os dois.
    ids = ids.split(',') if ids.is_a?(String)

    kind_value = IepOptionKinds.value_of(kind)
    allowed_ids = IepOption.by_kind(kind).where(id: Array(ids).reject(&:blank?)).pluck(:id)

    rows = send(association)

    rows.each do |row|
      next unless row.iep_option&.kind == kind_value

      row.mark_for_destruction unless allowed_ids.include?(row.iep_option_id)
    end

    existing_ids = iep_selected_option_ids_for(association, kind)
    (allowed_ids - existing_ids).each { |option_id| rows.build(iep_option_id: option_id) }
  end
end
