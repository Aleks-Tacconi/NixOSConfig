# Web and TypeScript tooling and CSS lint configuration.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    tailwindcss-language-server
    vscode-langservers-extracted
    prettier
    htmlhint
    typescript-language-server
    typescript
    eslint
    eslint_d
    stylelint
    stylelint-lsp
    bun
  ];

  home.file.".stylelint.config.js".text = ''
    module.exports = {
      extends: "stylelint-config-standard",
      plugins: ["stylelint-scss"],
      rules: {
        "at-rule-no-unknown": null,
        "scss/at-rule-no-unknown": true,
        "no-descending-specificity": null,
      },
    };
  '';
}
