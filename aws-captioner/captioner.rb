# https://github.com/ruby-no-kai/signage-app/blob/main/caption/serve.rb
require 'thread'
require 'aws-sdk-transcribestreamingservice'
require 'aws-sdk-translate'

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

class StdinInput
  def initialize
    @on_data = proc { }
  end

  def on_data(&block)
    @on_data = block
    self
  end

  def start
    @th = Thread.new do
      $stdin.binmode
      $stderr.puts({binmode?: $stdin.binmode?}.inspect)
      until $stdin.eof?
        buf = $stdin.read(32000) # 256Kb
        @on_data.call buf
      end
    end.tap { _1.abort_on_exception = true }
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

CaptionData = Data.define(:result_id, :is_partial, :transcript, :translated_transcript)

class GenericOutput
  def initialize()
    @data_lock = Mutex.new
    @data = {}
  end

  def feed(event, translator = nil)
    @data_lock.synchronize do
      event.transcript.results.each do |result|
        transcript = result.alternatives[0]&.transcript

        caption = CaptionData.new(
          result_id: result.result_id,
          is_partial: result.is_partial,
          transcript: transcript,
          translated_transcript: translator&.translate(text: transcript) # 富豪的に呼んでいるが、is_partial: false のときだけでもいいかも？
        )

        @data[result.result_id] = caption if caption.transcript
      end
    end
  end

  def start
    @th = Thread.new do
      loop do
        begin
          data = nil
          @data_lock.synchronize do
            data = @data
            @data = {}
          end

          data.each do |k, caption|
            handle(caption)
          end
        end
        sleep 0.7
      end
    end.tap { _1.abort_on_exception = true }
  end
end

class StderrOutput < GenericOutput
  def handle(caption)
    $stderr.puts caption.to_h.to_json
  end
end

class Watchdog
  NO_AUTO_RESTART_HOURS = ((0..9).to_a + (21..23).to_a).map { (_1 - 9).then { |jst|  jst < 0 ? 24+jst : jst } }

  def initialize(timeout: 1800, enabled: false)
    @timeout = timeout
    @last = Time.now.utc
    @enabled = enabled
  end

  attr_accessor :enabled

  def alive!
    @last = Time.now.utc
  end

  def start
    @th ||= Thread.new do
      loop do
        sleep 15
        now = Time.now.utc
        if (now - @last) > @timeout
          $stderr.puts "Watchdog engages!"
          next if NO_AUTO_RESTART_HOURS.include?(now.hour)
          if @enabled
            $stderr.puts "doggo shuts down this process"
            raise
          end
        end
      end
    end.tap { _1.abort_on_exception =  true }
  end
end

watchdog = Watchdog.new(enabled: ARGV.delete('--watchdog'))
watchdog.start()

input = StdinInput.new
engine = TranscribeEngine.new
translator = TranslateEngine.new
output = StderrOutput.new

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
