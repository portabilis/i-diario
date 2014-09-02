unless Entity.exists?
  Entity.create!(
    name: "Prefeitura",
    domain: "prefeitura.educacao.local",
    config: {
      database: "novo_educacao_development"
    }
  )
end

unless User.exists?
  User.create!(
    email: 'admin@example.com',
    password: '12345678',
    password_confirmation: '12345678',
    first_name: 'Usuario',
    last_name: 'Administrador',
    login: 'admin',
    phone: '(11) 9988-7766',
    cpf: '639.290.118-32',
    authorize_email_and_sms: false
  )
end
