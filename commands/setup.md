---
argument-hint: [category|server-names]
description: Setup MCP servers (optional: category or comma-separated server names)
---

# Setup MCP Servers

Intelligently manages MCP server configurations by comparing master config with existing project setup and allowing selective addition of new MCPs.

## Usage

```
/setup-mcp                           # Interactive mode
/setup-mcp research                  # Add all research MCPs
/setup-mcp seo                       # Add all SEO MCPs
/setup-mcp frontend                  # Add all frontend MCPs
/setup-mcp exa,brave-search          # Add specific MCPs (comma-separated)
```

## Categories

- **research**: exa, brave-search, reddit-mcp, reddit
- **seo**: dataforseo, firecrawl-mcp
- **frontend**: chrome-devtools, vibe-annotations, shadcn

## Description

This command sets up MCP (Model Context Protocol) servers for a project by:

1. Reading master MCP configuration from `~/.claude/mcp-config.json`
2. Comparing with existing `.mcp.json` in the project (if it exists)
3. Identifying new MCPs that aren't in the current project
4. Asking user which new MCPs they want to add
5. Adding selected MCPs and enabling them by default
6. Preserving existing MCP configurations and their enabled/disabled state

## Implementation

```javascript
// Read master MCP configuration from ~/.claude/mcp-config.json
const homeDir = Deno.env.get("HOME");
const masterConfigPath = `${homeDir}/.claude/mcp-config.json`;

let masterConfig;
try {
  const masterConfigText = await Deno.readTextFile(masterConfigPath);
  masterConfig = JSON.parse(masterConfigText);
} catch (error) {
  console.log(`❌ Could not read master config from ${masterConfigPath}`);
  console.log("Please ensure the file exists and contains valid JSON.");
  Deno.exit(1);
}

// Check for existing .mcp.json in project
let existingConfig = { mcpServers: {} };
let existingMcpNames = [];
try {
  const existingConfigText = await Deno.readTextFile(".mcp.json");
  existingConfig = JSON.parse(existingConfigText);
  existingMcpNames = Object.keys(existingConfig.mcpServers || {});
} catch {
  // No existing config, that's fine
}

// Define category mappings
const categories = {
  research: ["exa", "brave-search", "reddit-mcp", "reddit"],
  seo: ["dataforseo", "firecrawl-mcp"],
  frontend: ["chrome-devtools", "vibe-annotations", "shadcn"]
};

// Get argument from $ARGUMENTS
const argument = "$ARGUMENTS".trim();

// Find new MCPs that aren't in the existing config
const masterMcpNames = Object.keys(masterConfig.mcpServers);
const newMcpNames = masterMcpNames.filter(
  (name) => !existingMcpNames.includes(name)
);

if (newMcpNames.length === 0) {
  console.log(
    "✅ All MCPs from master config are already present in this project."
  );
  console.log(`Current MCPs: ${existingMcpNames.join(", ")}`);
  Deno.exit(0);
}

let selectedMcps = [];

// Handle argument-based selection
if (argument) {
  // Check if it's a category
  if (categories[argument]) {
    selectedMcps = categories[argument].filter(name => newMcpNames.includes(name));
    if (selectedMcps.length === 0) {
      console.log(`ℹ️  All MCPs in category '${argument}' are already installed.`);
      Deno.exit(0);
    }
    console.log(`📦 Adding ${selectedMcps.length} MCP(s) from category '${argument}': ${selectedMcps.join(", ")}`);
  } else {
    // Treat as comma-separated server names
    const requestedNames = argument.split(",").map(s => s.trim());
    selectedMcps = requestedNames.filter(name => {
      if (!masterMcpNames.includes(name)) {
        console.log(`⚠️  Warning: '${name}' not found in master config`);
        return false;
      }
      if (existingMcpNames.includes(name)) {
        console.log(`ℹ️  '${name}' is already installed`);
        return false;
      }
      return true;
    });

    if (selectedMcps.length === 0) {
      console.log("❌ No valid MCPs to add.");
      Deno.exit(0);
    }
    console.log(`📦 Adding ${selectedMcps.length} MCP(s): ${selectedMcps.join(", ")}`);
  }
} else {
  // Interactive mode - ask user which MCPs to add
  console.log(`\n📋 Found ${newMcpNames.length} new MCP(s) available:`);
  newMcpNames.forEach((name, index) => {
    console.log(`${index + 1}. ${name}`);
  });

  console.log("\nWhich MCPs would you like to add?");
  console.log("- Type 'all' to add all new MCPs");
  console.log("- Type specific numbers (e.g., '1,3,5') to add selected MCPs");
  console.log("- Type 'none' to cancel");

  const input = prompt("Your choice: ");

  if (input === "all") {
    selectedMcps = [...newMcpNames];
  } else if (input === "none" || !input) {
    console.log("❌ Operation cancelled.");
    Deno.exit(0);
  } else {
    // Parse comma-separated numbers
    const indices = input.split(",").map((s) => parseInt(s.trim()) - 1);
    selectedMcps = indices
      .filter((i) => i >= 0 && i < newMcpNames.length)
      .map((i) => newMcpNames[i]);
  }
}

if (selectedMcps.length === 0) {
  console.log("❌ No valid MCPs selected.");
  Deno.exit(0);
}

// Add selected MCPs to existing config
for (const mcpName of selectedMcps) {
  existingConfig.mcpServers[mcpName] = masterConfig.mcpServers[mcpName];
}

// Create .claude directory if it doesn't exist
await Deno.mkdir(".claude", { recursive: true });

// Write updated .mcp.json
await Deno.writeTextFile(".mcp.json", JSON.stringify(existingConfig, null, 2));

// Handle settings.local.json
let settings = {};
try {
  const existingSettings = await Deno.readTextFile(
    ".claude/settings.local.json"
  );
  settings = JSON.parse(existingSettings);
} catch {
  // File doesn't exist, start with empty settings
}

// Ensure enableAllProjectMcpServers is set to false
settings.enableAllProjectMcpServers = false;

// Initialize enabledMcpjsonServers if it doesn't exist
if (!settings.enabledMcpjsonServers) {
  settings.enabledMcpjsonServers = [];
}

// Initialize disabledMcpjsonServers if it doesn't exist
if (!settings.disabledMcpjsonServers) {
  settings.disabledMcpjsonServers = [];
}

// Add newly selected MCPs to enabled list
for (const mcpName of selectedMcps) {
  if (!settings.enabledMcpjsonServers.includes(mcpName)) {
    settings.enabledMcpjsonServers.push(mcpName);
  }
}

await Deno.writeTextFile(
  ".claude/settings.local.json",
  JSON.stringify(settings, null, 2)
);

console.log(
  `\n✅ Added ${selectedMcps.length} new MCP(s): ${selectedMcps.join(", ")}`
);
console.log("✅ New MCPs added to enabledMcpjsonServers list");
console.log("✅ Existing MCP configurations preserved");

console.log("\n🔄 Please restart Claude Code for the changes to take effect!");
```
