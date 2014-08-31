unless Entity.exists?
  Entity.create!(
    name: "Prefeitura",
    domain: "prefeitura.educacao.local",
    config: {
      database: "novo_educacao_development"
    }
  )
end
