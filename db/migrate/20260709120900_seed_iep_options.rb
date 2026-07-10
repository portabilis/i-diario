class SeedIepOptions < ActiveRecord::Migration[5.0]
  # AR mínimo isolado: seed idempotente, roda por Entity (multi-tenant).
  class Option < ActiveRecord::Base
    self.table_name = 'iep_options'
  end

  # Mapeamento de kind (mesmos valores da enumeration usada no model IepOption)
  KINDS = {
    0 => [ # communication_profile — Perfil de comunicação
      'Faz uso de comunicação funcional empregando recursos verbais e/ou sinalização',
      'Apresenta barreiras de comunicação oral (necessita de CAA)',
      'Barreira linguística na comunicação e informação decorrentes da ausência/restrição de percepção auditiva/visual',
      'Barreira na comunicação clara e simples nas interações com professores e pares que comprometem o acesso, a permanência e a participação nos processos de aprendizagem'
    ],
    1 => [ # social_interaction_profile — Perfil de interação social e comportamental
      'Prefere atividades solitárias',
      'Apresenta dificuldade com normas sociais',
      'Apresenta sensibilidade sensorial',
      'Apresenta resistência a mudanças na rotina',
      'Apresenta episódios de desregulação que demanda mediação pontual',
      'Apresenta comportamentos disruptivos severos com risco à integridade física (auto ou heteroagressividade) exigindo suporte constante para segurança e participação'
    ],
    2 => [ # autonomy — Autonomia e vida diária
      'Independente',
      'Necessita de auxílio parcial (amarrar tênis, colocar casaco)',
      'Dependência total (necessita de alguém para auxiliar nos processos de vida diária)'
    ],
    3 => [ # accompaniment — Realiza acompanhamento com
      'Psicólogo', 'Fonoaudiólogo', 'Terapeuta Ocupacional', 'Neuropediatra', 'Fisioterapeuta', 'Outro'
    ],
    4 => [ # support_type — Tipos de suporte
      'Atendimento Educacional Especializado (AEE)',
      'Sala de recursos multifuncionais',
      'Profissional de apoio escolar',
      'Intérprete de Libras',
      'Material didático adaptado',
      'Comunicação alternativa (CAA)',
      'Tecnologia Assistiva'
    ],
    5 => [ # instructional_accommodation — Acomodações previstas - Instrucionais
      'Uso de materiais concretos', 'Colar pistas visuais', 'Mapas mentais', 'Notas guiadas',
      'Tutoria de amigos/pares', 'Tutoria do auxiliar/professor', 'Rotina visual anexada na parede',
      'Previsibilidade', 'Pareamentos'
    ],
    6 => [ # environmental_accommodation — Acomodações previstas - Ambientais
      'Recursos visuais colados na escola',
      'Paredes sem muita informação no campo de visão',
      'Lugar apropriado para um melhor desempenho do estudante',
      'Mesas e cadeiras apropriadas conforme necessidade do aluno',
      'Tapetes',
      'Saídas com objetivos para autorregulação',
      'Objeto para aluno segurar, manipular e conseguir focar',
      'Linguagem simples e direta'
    ],
    7 => [ # assessment_accommodation — Acomodações previstas - Avaliação
      'Fonte ampliada', 'Braille', 'Libras', 'Tecnologia assistiva', 'Comunicação alternativa',
      'Uso de material adaptado pelo núcleo', 'Maior espaçamento entre as questões',
      'Diminuição de questões e comandos simples e diretos'
    ]
  }.freeze

  def up
    KINDS.each do |kind, descriptions|
      descriptions.each_with_index do |description, index|
        Option.find_or_create_by!(kind: kind, description: description) do |option|
          option.position = index + 1
          option.active = true
        end
      end
    end
  end

  def down
    KINDS.each do |kind, descriptions|
      Option.where(kind: kind, description: descriptions).delete_all
    end
  end
end
