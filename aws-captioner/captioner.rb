# https://github.com/ruby-no-kai/signage-app/blob/main/caption/serve.rb

require_relative './io'
require_relative './watchdog'
require_relative './transcribe_engine'
require_relative './refiner'
require_relative './translate_engine'

CaptionData = Data.define(:result_id, :is_partial, :transcript, :transcript_refined, :translated_transcript)

watchdog = Watchdog.new(enabled: ARGV.delete('--watchdog'))
watchdog.start()

input = StdinInput.new
engine = TranscribeEngine.new
translator = TranslateEngine.new
refiner = Refiner.new(backend: :bedrock)
output = AppSyncOutput.new(debug: true)

# Called when 256KB of input (1 second when -ar 16000) is received
input.on_data do |chunk|
  # Pass audio chunk to TranscribeEngine
  engine.feed(chunk)
end

# Called when transcription is available
engine.on_transcript_event do |event|
  # Notify the watchdog
  watchdog&.alive!

  event.transcript.results.each do |result|
    transcript = result.alternatives[0]&.transcript

    if transcript
      if !result.is_partial
        refined = refiner.refine(transcript)
      end

      caption = CaptionData.new(
        result_id: result.result_id,
        is_partial: result.is_partial,
        transcript: transcript,
        transcript_refined: refined,
        translated_transcript: translator&.translate(text: transcript) # 富豪的に呼んでいるが、is_partial: false のときだけでもいいかも？
      )

      output.feed(caption)
    end
  end
end

begin
  output.start
  call = engine.start
  input.start
  p call.wait.inspect
rescue Interrupt
  engine.finish
end
