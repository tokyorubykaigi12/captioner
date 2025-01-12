# https://github.com/ruby-no-kai/signage-app/blob/main/caption/serve.rb

require_relative './io'
require_relative './watchdog'
require_relative './transcribe_engine'
require_relative './translate_engine'

CaptionData = Data.define(:result_id, :is_partial, :transcript, :translated_transcript)

watchdog = Watchdog.new(enabled: ARGV.delete('--watchdog'))
watchdog.start()

input = StdinInput.new
engine = TranscribeEngine.new
translator = TranslateEngine.new
output = AppSyncOutput.new

# Called when 256KB of input (1 second when -ar 16000) is received
input.on_data do |chunk|
  # Pass audio chunk to TranscribeEngine
  engine.feed(chunk)
end

# Called when transcription is available
engine.on_transcript_event do |e|
  # Notify the watchdog
  watchdog&.alive!

  output.feed(e, translator)
end

begin
  output.start
  call = engine.start
  input.start
  p call.wait.inspect
rescue Interrupt
  engine.finish
end
