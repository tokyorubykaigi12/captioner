# frozen_string_literal: true

class TranslateEngine
  def initialize
    @client = Aws::Translate::Client.new(region: 'ap-northeast-1')
  end

  def translate(text:)
    @client.translate_text(
      text: text,
      source_language_code: 'ja',
      target_language_code: 'en',
      settings: {
        formality: 'FORMAL'
      }
    ).translated_text
  end
end
