## setup

### required

docker compose .

## run

```sh
docker compose up --build -d
```

## try

using mosquitto pub/sub client.
install mosquitto if you need.

```sh
brew install mosquitto
```

`-h` is host option.
`-t` is topic option.
`-m` is for publisher, it's define message.

### subscribe

```sh
mosquitto_sub -h localhost -t test/test_topic
```

### publish

```sh
mosquitto_pub -h localhost -t test/test_topic -m "hello"
```
