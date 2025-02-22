import { useEffect, useState, useRef } from "react";
import { events, EventsChannel } from "aws-amplify/data";

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
  const [channel, setChannel] = useState<EventsChannel | null>(null);
  const transcriptDivScroller = useRef<HTMLDivElement>(null);
  const translationDivScroller = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let isAborted = false;

    const connectToAmplify = async () => {
      try {
        const urlParams = new URLSearchParams(window.location.search);
        const channelParam = urlParams.get("channel") || "test";
        const c = await events.connect(`/default/${channelParam}`);
        if (isAborted === true) {
          c.close();
          return;
        }
        c.subscribe({
          next: (data) => {
            console.log(data.event);

            // Check for commands
            if (data.event.command === "jibaku") {
              window.location.reload();
              return;
            }

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

            transcriptDivScroller.current?.scrollIntoView({
              behavior: "smooth",
            });
            translationDivScroller.current?.scrollIntoView({
              behavior: "smooth",
            });
          },
          error: (error) => {
            console.error("Subscription error:", error);
          },
        });
        setChannel(c);
        console.log("subscribed!");
      } catch (error) {
        console.error("Connection error:", error);
      }
    };

    connectToAmplify();

    return () => {
      isAborted = true;
      if (channel) {
        channel?.close();
        console.log("unsubscribed!");
      }
    };
  }, []);

  return (
    <>
      <p className="messages">
        {messages.map((message) => (
          <>
            <span
              key={message.result_id}
              className={message.is_partial ? "partial" : ""}
            >
              {message.translation}
            </span>{" "}
            <br />
          </>
        ))}
        <div
          ref={translationDivScroller}
          style={{ float: "left", clear: "both" }}
        />
      </p>
      <hr />
      <div className="messages">
        {messages.map((message) => (
          <span
            key={message.result_id}
            className={message.is_partial ? "partial" : ""}
          >
            {message.transcript
              .replaceAll("ルビ", "Ruby")
              .replaceAll("性的", "静的")
              .replaceAll("レズ", "Rails")
              .replaceAll("。", "。\n")
              .split("\n")
              .map((part) => (
                <>
                  {part}
                  <br />
                </>
              ))}
          </span>
        ))}
        <div
          ref={transcriptDivScroller}
          style={{ float: "left", clear: "both" }}
        />
      </div>
    </>
  );
}

export default App;
