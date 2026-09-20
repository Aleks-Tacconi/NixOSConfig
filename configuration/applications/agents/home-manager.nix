{ pkgs, ... }:

{
  programs.opencode = {
    enable = true;
    package = pkgs.opencode;
  };

  # OpenCode configuration
  xdg.configFile = {
    "opencode/AGENTS.md".source = ../../../agents/AGENTS.md;
    "opencode/opencode.jsonc".source = ../../../agents/opencode/opencode.jsonc;
    "opencode/skills".source = ../../../agents/skills;
  };

  home.file = {
    # Shared agent standards
    ".agents/AGENTS.md".source = ../../../agents/AGENTS.md;
    ".agents/skills".source = ../../../agents/skills;

    # Gemini / agy configuration
    ".gemini/GEMINI.md".source = ../../../agents/AGENTS.md;
    ".gemini/AGENTS.md".source = ../../../agents/AGENTS.md;
    ".gemini/skills".source = ../../../agents/skills;
    ".gemini/config/mcp_config.json".source = ../../../agents/agy/mcp_config.json;
    ".gemini/config/config.json".source = ../../../agents/agy/config.json;
    ".gemini/settings.json".source = ../../../agents/agy/settings.json;

    # Claude configuration
    ".claude/CLAUDE.md".source = ../../../agents/AGENTS.md;
    ".claude/skills".source = ../../../agents/skills;

    # Cursor configuration
    ".cursorrules".source = ../../../agents/AGENTS.md;
    ".cursor/skills".source = ../../../agents/skills;
  };
}
