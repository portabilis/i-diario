module LessonsBoardsHelper
  # Reproduz o formato que Select2Input#parse_collection grava em `data-elements`, para que a
  # resposta remota do index (index.js.erb) consiga recriar os filtros em cascata com as mesmas
  # opções que seriam renderizadas em um carregamento completo da página.
  def select2_elements_json(elements)
    parsed_elements = elements.compact.map do |element|
      {
        id: element.id,
        name: element.try(:name) || element.to_s,
        text: element.try(:text) || element.to_s
      }
    end

    parsed_elements.unshift(id: 'empty', name: '<option></option>', text: '') if parsed_elements.any?

    parsed_elements.to_json
  end
end
