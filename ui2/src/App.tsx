import { useEffect, useState } from "react";
import { Amplify } from "aws-amplify";
import { events } from "aws-amplify/data";

import "./App.css";

interface Message {
  result_id: string;
  is_partial: boolean;
  transcript: string;
  transcript_original: string;
  translation: string;
}

function App() {
  const [messages, setMessages] = useState<Message[]>([]);

  useEffect(() => {
    Amplify.configure({
      API: {
        Events: {
          endpoint: import.meta.env.VITE_AMPLIFY_ENDPOINT,
          region: import.meta.env.VITE_AMPLIFY_REGION,
          defaultAuthMode: "apiKey",
          apiKey: import.meta.env.VITE_AMPLIFY_API_KEY,
        },
      },
    });

    const connectToAmplify = async () => {
      try {
        const channel = await events.connect("/default/test");
        channel.subscribe({
          next: (data) => {
            console.log("Received data:", data);
            setMessages((prevMessages) => {
              const lastMessage = prevMessages[prevMessages.length - 1];
              if (lastMessage?.result_id === data.event.result_id) {
                // replace the last message
                return [...prevMessages.slice(0, -1), { ...data.event }];
              } else {
                // simply append
                return [...prevMessages, { ...data.event }];
              }
            });
          },
          error: (error) => {
            console.error("Subscription error:", error);
          },
        });
      } catch (error) {
        console.error("Connection error:", error);
      }
    };

    connectToAmplify();

    return () => {
      // TODO: call events.unsubscribe()
    };
  }, []);

  return (
    <>
      <p className="messages">
        {messages.map((message) => (
          <span key={message.result_id}>{message.transcript}</span>
        ))}
      </p>
      <hr />
      <p className="messages">
        {messages.map((message) => (
          <span key={message.result_id}>{message.translation}</span>
        ))}
      </p>
    </>
  );
}

export default App;
