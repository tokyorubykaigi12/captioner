import mqtt from "mqtt";
import { useEffect, useState } from "react";

function App() {
  const [client, setClient] = useState<mqtt.MqttClient | null>(null);
  const [isSubscribed, setIsSubscribed] = useState<boolean>(false);
  const [message, setMessage] = useState<string>("caption will be here");

  useEffect(() => {
    console.log("App component mounted");

    if (!client) {
      const url = "ws://localhost:2883";
      setClient(
        mqtt.connect(url, {
          clean: true,
          reconnectPeriod: 1000,
          connectTimeout: 30 * 1000,
        })
      );
    } else {
      client.on("connect", () => {
        console.log("connected");
      });

      if (!isSubscribed) {
        client.subscribe("test", (error) => {
          if (error) {
            console.log("subscribe error", error);
            return;
          }
          setIsSubscribed(true);
          console.log("subscribed");
        });
      } else {
        client.on("message", (topic, payload) => {
          setMessage(payload.toString());
          console.log(`message received, topic: ${topic}, payload: ${payload.toString()}`);
        });
      }
    }
  }, [client, isSubscribed]);

  return (
    <div>
      <h1>Hi, Tokyo RubyKaigi 12.</h1>
      <p>{message}</p>
    </div>
  );
}

export default App;
