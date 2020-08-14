class TranslationsFetcher
  class << self
    def fetch
      Rails.cache.fetch(Translation.cache_key, expires_in: 1.day) { translation_hash }
    end

    private

    def translation_hash
      translations = {}

      Translation.all.each do |translation|
        next if translation.translation.blank?

        translations[translation.key] = translation.translation
      end

      translations
    end
  end
end
