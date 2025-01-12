require 'aws-sdk-bedrockruntime'

class Refiner
  def initialize
    @bedrock = Aws::BedrockRuntime::Client.new(region: 'ap-northeast-1')
  end

  def refine(text)
    # Skip if the transcription is too short. It won't produce good results anyway.
    if text.length < 20
      return nil
    end

    begin
      invocation = @bedrock.invoke_model(
        model_id: 'anthropic.claude-3-5-sonnet-20240620-v1:0',
        content_type: 'application/json',
        accept: 'application/json',
        body: JSON.generate({
          anthropic_version: "bedrock-2023-05-31",
          max_tokens: 1000,
          messages: [
            {
              role: "user",
              content: <<~PROMPT
                これはRubyに関するカンファレンスの発表の書き起こしです。以下のルールにしたがって、書き起こしを読みやすくしてください。

                - 「えっと」や「まー」などのフィラーを取り除いてください
                - Ruby に関連しそうな用語は正しい表記にしてください（「ルビー」→  Ruby など）
                - 以上に述べた変更以外は行わず、なるべく元の書き起こしをそのまま出力する。

                読みやすくなった書き起こしのみを出力すること。

                #{text}
              PROMPT
            }
          ]
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
end
