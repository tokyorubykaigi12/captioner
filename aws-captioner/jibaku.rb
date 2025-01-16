require 'faraday'

res = Faraday.post(
  ENV.fetch('AMPLIFY_ENDPOINT'),
  JSON.generate({
    "channel" => "default/test",
    "events" => [
      JSON.generate({"command": "jibaku"})
    ]
  }), {
    "Content-Type" => "application/json",
    "X-Api-Key" => ENV.fetch('AMPLIFY_API_KEY'),
  }
)

pp JSON.parse(res.body)
