# https://github.com/ruby-no-kai/signage-app/blob/main/caption/serve.rb

require_relative './io'
require_relative './watchdog'
require_relative './transcribe_engine'
require_relative './refiner'
require_relative './translator'

CaptionData = Data.define(:result_id, :is_partial, :transcript, :transcript_original, :translation)

watchdog = Watchdog.new(enabled: ARGV.delete('--watchdog'))
watchdog.start()

input = StdinInput.new
engine = TranscribeEngine.new
refiner = Refiner.new(backend: :anthropic)
translator = Translator.new
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
      refined = refiner.refine(transcript)
      translated = translator.translate(refined)

      caption = CaptionData.new(
        result_id: result.result_id,
        is_partial: result.is_partial,
        transcript: refined,
        transcript_original: transcript,
        translation: translated,
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
