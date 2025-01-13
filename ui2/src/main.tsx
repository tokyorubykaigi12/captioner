import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import App from "./App.tsx";

import { Amplify } from "aws-amplify";

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

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
