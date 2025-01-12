require 'thread'

require 'faraday'

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

class GenericOutput
  def initialize()
    @data_lock = Mutex.new
    @data = {}
  end

  def feed(caption)
    @data_lock.synchronize do
      @data[caption.result_id] = caption if caption.transcript
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

class AppSyncOutput < GenericOutput
  def initialize(debug: false)
    super()
    @debug = debug
  end

  def handle(caption)
    if @debug
      $stderr.puts "Ja (orig): #{caption.transcript}"
      $stderr.puts "Ja (refn): #{caption.transcript_refined}"
      $stderr.puts "En (tnsl): #{caption.translated_transcript}"
      $stderr.puts ""
    end

    Faraday.post(
      ENV.fetch('AMPLIFY_ENDPOINT'),
      JSON.generate({
        "channel" => "default/test",
        "events" => [
          JSON.generate(caption.to_h)
        ]
      }), {
        "Content-Type" => "application/json",
        "X-Api-Key" => ENV.fetch('AMPLIFY_API_KEY'),
      })
  end
end
