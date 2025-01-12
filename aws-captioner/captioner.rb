# frozen_string_literal: true

# https://github.com/ruby-no-kai/signage-app/blob/main/caption/serve.rb

require 'aws-sdk-transcribestreamingservice'
require 'aws-sdk-translate'

require_relative './io'
require_relative './watchdog'

CaptionData = Data.define(:result_id, :is_partial, :transcript, :translated_transcript)

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

class TranscribeEngine
  def initialize
    @client = Aws::TranscribeStreamingService::AsyncClient.new(region: 'ap-northeast-1')
    @input_stream = Aws::TranscribeStreamingService::EventStreams::AudioStream.new
    @output_stream = Aws::TranscribeStreamingService::EventStreams::TranscriptResultStream.new

    @output_stream.on_bad_request_exception_event do |exception|
      raise exception
    end

    @output_stream.on_event do |event|
      p event unless event.is_a?(Aws::TranscribeStreamingService::Types::TranscriptEvent)
    end
  end

  attr_reader :output_stream

  def feed(audio_chunk)
    @input_stream.signal_audio_event_event(audio_chunk: audio_chunk)
    self
  rescue Seahorse::Client::Http2ConnectionClosedError
    @client.connection.errors.each do |e|
      p e
    end
    raise
  end

  def start
    @client.start_stream_transcription(
      language_code: 'ja-JP',
      media_encoding: "pcm",
      media_sample_rate_hertz: 16000,

      enable_partial_results_stabilization: true,
      partial_results_stability: 'high',

      vocabulary_name: 'trk12', # custom vocabulary

      input_event_stream_handler: @input_stream,
      output_event_stream_handler: @output_stream,
    )
  end

  def finish
    @input_stream.signal_end_stream
  end

  def on_transcript_event(&block)
    output_stream.on_transcript_event_event(&block)
    self
  end
end


watchdog = Watchdog.new(enabled: ARGV.delete('--watchdog'))
watchdog.start()

input = StdinInput.new
engine = TranscribeEngine.new
translator = TranslateEngine.new
output = AppSyncOutput.new

input.on_data do |chunk|
  p now: Time.now, on_audio: chunk.bytesize
  engine.feed(chunk)
end

engine.on_transcript_event do |e|
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
