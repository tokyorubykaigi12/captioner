## setup
```sh
rbenv install
bundle install
```

```sh
envchain --set terfno-aws-trk12 AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
```

## how to execute
choice your intended audio input.
```sh
ffmpeg -f avfoundation -list_devices true -i ""
```

and execute. `:2` is id of your audio input. please replace it.
```sh
ffmpeg -f avfoundation -i :2 -f s16le -ar 16000 -ac 1 - | envchain terfno-aws-trk12 ruby ./captioner.rb
```
