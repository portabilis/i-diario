class Translator
  class << self
    def t(*args)
      translate(*args)
    end

    def translate(*args)
      custom_translation(args[0]) || I18n.translate(*args)
    end

    private

    def custom_translation(key)
      TranslationsFetcher.fetch[key]
    end
  end
end
