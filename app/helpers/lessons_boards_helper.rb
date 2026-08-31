module LessonsBoardsHelper
  # Reproduz o formato que Select2Input#parse_collection grava em `data-elements`, para a resposta
  # remota recriar os filtros com as mesmas opções do carregamento completo da página.
  #
  # `to_json` escapa aspas e entidades HTML, então interpolar o resultado com `raw` é seguro.
  def select2_elements_json(elements)
    parsed_elements = elements.compact.map { |element| select2_element(element) }
    parsed_elements.unshift(select2_empty_element) if parsed_elements.any?

    parsed_elements.to_json
  end

  private

  def select2_element(element)
    name = element.try(:name) || element.to_s

    return { name: name } if element.id.blank?

    { id: element.id, name: name, text: element.try(:text) || element.to_s }
  end

  def select2_empty_element
    { id: Select2Input::EMPTY_ELEMENT_ID, name: '<option></option>', text: '' }
  end
end
