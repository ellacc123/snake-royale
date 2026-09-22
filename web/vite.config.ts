import { defineConfig } from "vite";

export default defineConfig({
  server: {
    port: 5173,
    // Everything under /api is handled by the OCaml game server, which keeps the browser
    // and the backend on one origin so there's no CORS involved in normal use.
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
      },
    },
  },
});
