import stylistic from "@stylistic/eslint-plugin";
import globals from "globals";
import js from "@eslint/js";

export default [
  js.configs.recommended,
  {
    ignores: [
      "**/*\\{.,-}min.js",
      "**/jquery.ui.widget.js",
      "**/coverage/",
      "backstop/reports/",
      "app/assets/config/",
    ],

    plugins: {
      "@stylistic": stylistic,
    },

    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.jquery,
      },

      ecmaVersion: 2015, // ECMA 6
      sourceType: "script",
    },

    linterOptions: {
      reportUnusedDisableDirectives: "warn"
    },

    rules: {
      // Best Practices
      "accessor-pairs": 2,
      "block-scoped-var": 2,
      complexity: [2, 6],
      "consistent-return": 1,
      "dot-notation": 1,
      eqeqeq: 2,
      "guard-for-in": 2,
      "no-caller": 1,
      "no-div-regex": 2,
      "no-else-return": 2,
      "no-empty-function": 2,
      "no-eq-null": 2,
      "no-eval": 2,
      "no-extend-native": 2,
      "no-extra-bind": 2,
      "no-extra-label": 2,
      "no-implicit-coercion": 2,
      "no-implied-eval": 2,
      "no-invalid-this": 2,
      "no-iterator": 2,
      "no-labels": 2,
      "no-lone-blocks": 2,
      "no-loop-func": 2,
      "no-multi-str": 2,
      "no-new": 2,
      "no-new-func": 2,
      "no-new-wrappers": 2,
      "no-octal-escape": 2,
      "no-proto": 2,
      "no-restricted-properties": 2,
      "no-return-assign": 2,
      "no-script-url": 2,
      "no-self-compare": 2,
      "no-sequences": 2,
      "no-throw-literal": 2,
      "no-unmodified-loop-condition": 2,
      "no-unused-expressions": 2,
      "no-useless-call": 2,
      "no-useless-concat": 2,
      "no-useless-return": 2,
      "no-void": 2,
      "no-warning-comments": 1,
      "prefer-promise-reject-errors": 2,
      "require-await": 1,
      yoda: 1,
      
      // Variables
      "no-label-var": 2,
      "no-restricted-globals": 2,
      "no-shadow": 2,
      "no-undef-init": 2,
      "no-undefined": 2,
      "no-unused-vars": [
        2,
        {
          varsIgnorePattern: "^_.*$",
          argsIgnorePattern: "^_.*$",
        },
      ],
      "no-use-before-define": [
        2,
        {
          functions: false,
        },
      ],

      // ECMAScript 6
      "no-const-assign": 2,
      "no-var": 2,
      "prefer-const": 1,

      // Stylistic Issues
      camelcase: [
        1,
        {
          properties: "never",
        },
      ],
      "max-statements": [1, 30],
      "no-array-constructor": 1,
      "no-bitwise": 1,
      "no-lonely-if": 1,
      "no-multi-assign": 1,
      "no-negated-condition": 1,
      "no-nested-ternary": 1,
      "no-object-constructor": 2,
      "no-plusplus": [
        2,
        {
          allowForLoopAfterthoughts: true,
        },
      ],
      "no-unneeded-ternary": 2,
      "operator-assignment": 1,
      "@stylistic/dot-location": [2, "property"],
      "@stylistic/no-floating-decimal": 2,
      "@stylistic/no-multi-spaces": 2,
      "@stylistic/wrap-iife": 2,
      "@stylistic/array-bracket-spacing": 1,
      "@stylistic/block-spacing": 1,
      "@stylistic/brace-style": [
        1,
        "1tbs",
        {
          allowSingleLine: true,
        },
      ],
      "@stylistic/comma-spacing": 1,
      "@stylistic/comma-style": 1,
      "@stylistic/computed-property-spacing": 1,
      "@stylistic/eol-last": 1,
      "@stylistic/func-call-spacing": 1,
      "@stylistic/indent": [2, 2, {"SwitchCase": 0}],
      "@stylistic/jsx-quotes": [1, "prefer-single"],
      "@stylistic/key-spacing": 1,
      "@stylistic/keyword-spacing": 2,
      "@stylistic/linebreak-style": 1,
      "@stylistic/new-parens": 1,
      "@stylistic/no-mixed-operators": 2,
      "@stylistic/no-trailing-spaces": 2,
      "@stylistic/no-whitespace-before-property": 2,
      "@stylistic/semi": 2,
      "@stylistic/semi-spacing": 2,
      "@stylistic/space-before-blocks": 2,
      "@stylistic/space-before-function-paren": [
        2,
        {
          anonymous: "never",
          named: "never",
          asyncArrow: "always",
        },
      ],
      "@stylistic/space-in-parens": 1,
      "@stylistic/space-unary-ops": 1,
      "@stylistic/spaced-comment": [
        2,
        "always",
        {
          markers: ["= require"],
        },
      ],

      // deprecated options needing replacement (not style)
      "no-return-await": 2,
      "callback-return": 2,
      "global-require": 2,
      "handle-callback-err": 2,
      "no-mixed-requires": 1,
      "no-new-require": 1,
      "no-path-concat": 2,
      "no-process-env": 1,
      "no-process-exit": 2,
      "no-restricted-modules": 2,
      "no-sync": 1,
    },
  },
];
