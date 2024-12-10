# Azure memos

## trk12.txt

`trk12.txt` は Azure Custom Speech の train 用データです。
`{spoken>written}` の感じで、実際に口頭で発話される音に近いものを spoken、transcribe されたいものを written に入れている。
speech-translation にこれで train した model を接続している。

### 既知の課題

- 少なすぎる
  - 認識精度に変化がまだない
- written は翻訳後なのかどうかが不明瞭
  - custom speech 用なので、音 -> 文字だと思う。
  - 翻訳は別タスクのはず
