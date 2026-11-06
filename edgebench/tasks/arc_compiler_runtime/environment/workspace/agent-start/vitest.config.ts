import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    include: ["tests/stdlib-native.test.ts", "tests/result.test.ts", "tests/params-destructuring.test.ts"],
    testTimeout: 30000,
  },
});
