import { defineConfig } from "cypress";

export default defineConfig({
  pageLoadTimeout: 100000,
  e2e: {
    videoCompression: false,
    env: {
      url: "https://twistlock.bigbang.dev"
    },
    supportFile: false,
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
});