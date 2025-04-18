# Suprime o carregamento de gems que conflitam com a biblioteca padrão do Ruby 2.7
unless ENV['RAILS_ENV'] == 'test'
  %w[net/protocol net/imap net/pop net/smtp].each do |lib|
    $LOADED_FEATURES << "#{lib}.rb"
  end
end
