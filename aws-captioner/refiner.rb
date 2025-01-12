require 'anthropic'
require 'aws-sdk-bedrockruntime'

class Refiner
  def initialize(backend: :anthropic)
    @cache = MiniCache.new
    @backend = backend

    case @backend
    in :anthropic
      @anthropic = Anthropic::Client.new(
        access_token: ENV.fetch('ANTHROPIC_API_KEY'),
        anthropic_version: '2023-06-01'
      )
      @bedrock = nil
    in :bedrock
      @anthropic = nil
      @bedrock = Aws::BedrockRuntime::Client.new(region: 'ap-northeast-1')
    end
  end

  def refine(transcript)
    # 句点（「。」）を境界として分割し、is_partial であっても「。」の左側は refine する
    sentences = transcript.scan(/[^。]+。/)
    if sentences.length == 0
      return transcript
    end

    refined_sentences =
      sentences.map do |sentence|
        # すでに refine ずみの文であればキャッシュからもってくる
        @cache.cache(sentence) do
          case @backend
          in :anthropic
            refine_anthropic(transcript)
          in :bedrock
            refine_bedrock(transcript)
          end
        end
      end
    refined_sentences.join
  end

  def refine_anthropic(transcript)
    response = @anthropic.messages(
      parameters: {
        model: 'claude-3-5-sonnet-20240620',
        messages: messages(transcript),
        max_tokens: 1000,
      }
    )

    response["content"].first["text"]
  end

  def refine_bedrock(transcript)
    begin
      invocation = @bedrock.invoke_model(
        model_id: 'anthropic.claude-3-5-sonnet-20240620-v1:0',
        content_type: 'application/json',
        accept: 'application/json',
        body: JSON.generate({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 1000,
          messages: messages(transcript),
        })
      )
    rescue Aws::BedrockRuntime::Errors::ServiceError => e
      p e
      return nil
    end

    # Block until entire response is ready
    response_io = invocation.body
    response = response_io.string
    JSON.parse(response)["content"].first["text"]
  end

  def messages(transcript)
    [
      {
        role: "user",
        content: <<~__PROMPT__
          This is a Japanese transcripion of a conference talk about Ruby.
          Make the transcription more readable by following these instructions:

          - Remove filler words such as "あー", "えっと", "まあ".
          - Try to rewrite terms related to Ruby from their Katakana form to their proper form.
            - "ルビー" to "Ruby"
            - "レールズ" to "Rails"
          - Don't do other changes, and preserve the original transcription as much as possible.

          Return the refined transcription only. No other text is needed.

          TRANSCRIPTION:
          #{transcript}
        __PROMPT__
      }
    ]
  end
end

class MiniCache
  MAX_SIZE = 1000

  def initialize
    @storage = {}
  end

  def cache(key, &block)
    if val = @storage[key]
      return val
    else
      # Remove oldest entry if we're at capacity
      if @storage.size >= MAX_SIZE
        @storage.shift # remove oldest entry
      end
      @storage[key] = block.call
    end
  end
end
