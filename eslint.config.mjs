import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript"),
  {
    rules: {
      // TypeScript rules - disable problematic ones
      "@typescript-eslint/no-unused-vars": "off",
      "@typescript-eslint/no-explicit-any": "off",
      "@typescript-eslint/no-empty-object-type": "off",
      "@typescript-eslint/no-unused-expressions": "off",
      "@typescript-eslint/ban-ts-comment": "off",
      "@typescript-eslint/triple-slash-reference": "off",
      
      // React rules - disable problematic ones
      "react-hooks/exhaustive-deps": "off",
      "react/no-unescaped-entities": "off",
      
      // Next.js rules - disable img element warnings
      "@next/next/no-img-element": "off",
    },
    ignores: [
      "node_modules/**",
      ".next/**",
      "out/**",
      "build/**",
      "next-env.d.ts",
      "*.d.ts",
      "**/*.d.ts",
      ".next/types/**",
      ".next/static/**",
      ".next/static/chunks/**",
      ".next/static/development/**",
    ],
  },
];

export default eslintConfig;
