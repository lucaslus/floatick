import React from "react";
import ReactDOM from "react-dom/client";
import { api } from "./lib/api";
import { App } from "./App";
import "./index.css";
import "./i18n";

// Resolve the frame before rendering so Omarchy never flashes rounded corners.
async function mount() {
  try {
    if (await api.usesSystemWindowFrame()) {
      document.documentElement.dataset.windowFrame = "system";
    }
  } catch (error) {
    console.warn("Could not detect the desktop window frame", error);
  }

  ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}

void mount();
