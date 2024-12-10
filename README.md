# captioner for trk12

ざっくり設計
- captioner
  - 日本語音声を input として受けて、英語の字幕情報を output する
  - output は mqtt broker に向けて publish される
- mqtt broker
  - 開発環境では mosquitto を使っている
  - 本番では Amazon MQ (Apache ActiveMQ with MQTT) か AWS Iot Core (MQTT) みたいな感じで
  - 流す message についてはまだ設計してない
- ui
  - pure な React での実装をやろうとしている
  - MQTT broker のある topic を subscribe して、流れてくる字幕情報の表示と更新をやる

## todo

- [ ] 各種 captioner を試せる状態にする
- [ ] mqtt にわたす message の設計をする
  - MQTT は順序の保証がないはずなので、順序情報をもたせる(sequence)
  - あとから字幕の一部更新できるようにする(round)
- [ ] ui の実装をする
  - [ ] mqtt broker との接続
  - [ ] caption message を順序に応じて表示/更新する
