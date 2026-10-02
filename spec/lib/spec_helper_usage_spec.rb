# frozen_string_literal: true

require 'rails_helper'

# O `rails_helper` é quem liga a transação entre exemplos e infere o `type:` pelo diretório.
# Como a configuração do RSpec é global, um spec que exige só o `spec_helper` passa na suíte
# completa e escreve no banco sem limpeza quando roda sozinho, ou junto só de outros iguais a ele.
# Quem não precisa do Rails usa `spec_helper_lite` ou `spec_helper_form`.
RSpec.describe 'spec helper' do
  it 'does not have a spec that requires only the spec_helper' do
    # Casa só linha de require (inclusive require_relative e caminho relativo); helper citado em comentário não conta.
    spec_helper_require = /^\s*require(_relative)?\b.*\bspec_helper['"]/
    rails_helper_require = /^\s*require(_relative)?\b.*\brails_helper['"]/

    specs_without_rails_helper = Dir[Rails.root.join('spec/**/*_spec.rb').to_s].select do |spec_file|
      source = File.read(spec_file)

      source.match?(spec_helper_require) && !source.match?(rails_helper_require)
    end

    expect(specs_without_rails_helper).to be_empty
  end
end
