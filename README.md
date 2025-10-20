# kube-schemas.nvim

A Neovim plugin for managing Kubernetes YAML schema modelines. Automatically detect or search for the correct schema based on your resource's `apiVersion` and `kind`, and insert the appropriate YAML language server modeline.

## Features

- **Auto-detection**: Automatically detect the schema based on `apiVersion` and `kind` in your YAML file
- **Multi-document support**: Works with files containing multiple YAML documents separated by `---`
- **Manual search**: Browse and search through available Kubernetes schemas
- **Filter support**: Pre-filter schemas by name or description
- **Precise matching**: Deterministic schema matching based on exact API group, version, and kind
- **Integration**: Works with your existing `vim.ui.select` backend (Telescope, fzf-lua, Snacks, etc.)
- **Async fetching**: Uses plenary.curl for non-blocking HTTP requests

## Requirements

- Neovim >= 0.9.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### lazy.nvim

```lua
{
  "r35krag0th/kube-schemas.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = "yaml",
  opts = {
    -- Optional: customize the catalog URL
    -- catalog_url = "https://schemas.r35.io/api/json/catalog.json",
  },
  keys = {
    { "<localleader>yks", "<cmd>KubeSchemas search<cr>", desc = "Search Kubernetes schemas" },
    { "<localleader>yka", "<cmd>KubeSchemas auto<cr>", desc = "Auto-detect Kubernetes schema" },
  },
}
```

## Usage

### Auto-detect schema

Automatically detect the schema based on `apiVersion` and `kind` in the current YAML document. Place your cursor in the document you want to add a schema to and run:

```vim
:KubeSchemas auto
```

**Example:**

Given a file with:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
```

Running `:KubeSchemas auto` will insert:

```yaml
# yaml-language-server: $schema=https://schemas.r35.io/kubernetes/1.31/deployment-apps-v1.json
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
```

**Multi-document support:**

For files with multiple YAML documents, the plugin will detect the document containing your cursor and insert the schema modeline at the beginning of that specific document:

```yaml
---
# yaml-language-server: $schema=https://schemas.r35.io/kubernetes/1.31/service-v1.json
apiVersion: v1
kind: Service
metadata:
  name: my-service
---
# yaml-language-server: $schema=https://schemas.r35.io/kubernetes/1.31/deployment-apps-v1.json
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
```

### Search for schema

Open a picker to browse and search available schemas:

```vim
:KubeSchemas search
```

Optionally, provide a search query to pre-filter results:

```vim
:KubeSchemas search deployment
:KubeSchemas search helm release
:KubeSchemas search istio
```

## Configuration

The plugin can be configured via the `setup()` function:

```lua
require("kube-schemas").setup({
  catalog_url = "https://schemas.r35.io/api/json/catalog.json",
})
```

### Options

| Option        | Type   | Default                                        | Description                          |
| ------------- | ------ | ---------------------------------------------- | ------------------------------------ |
| `catalog_url` | string | `https://schemas.r35.io/api/json/catalog.json` | URL to fetch the schema catalog from |

### Catalog URLs

The plugin supports any JSON catalog that follows the schema store format. Here are some options:

**Default (recommended for Kubernetes):**

```lua
catalog_url = "https://schemas.r35.io/api/json/catalog.json"
```

This catalog includes comprehensive Kubernetes core resources and CRDs (Custom Resource Definitions) for popular tools like Flux, Istio, cert-manager, and more.

**SchemaStore.org:**

```lua
catalog_url = "https://www.schemastore.org/api/json/catalog.json"
```

This is a general-purpose schema catalog. Note that SchemaStore.org is unlikely to have many Kubernetes CRDs or version-specific core resources. It's better suited for general YAML files (GitHub Actions, Docker Compose, etc.) rather than Kubernetes-specific resources.

## How it works

1. The plugin fetches a catalog of Kubernetes schemas from a configurable URL
2. For auto-detection, it parses the current buffer to find `apiVersion` and `kind`
3. It matches these against the schema catalog using the resource kind, API group, and version
4. The appropriate YAML language server modeline is inserted at the top of the file
5. Your YAML language server (yaml-language-server) will use this schema for validation and completion

## Schema Sources

The default catalog URL (`https://schemas.r35.io/api/json/catalog.json`) aggregates schemas from multiple sources:

- **Kubernetes Core Resources**: Generated from official Kubernetes OpenAPI specifications
- **CRD Catalog**: [datreeio/CRDs-catalog](https://github.com/datreeio/CRDs-catalog) - Community-maintained JSON schemas for popular Kubernetes Custom Resource Definitions
- **SchemaStore.org**: [SchemaStore/schemastore](https://github.com/SchemaStore/schemastore) - General-purpose JSON schema catalog

## Acknowledgments

This plugin was inspired by:

- [yaml-companion.nvim](https://github.com/someone-stole-my-name/yaml-companion.nvim) - Dynamic YAML schema selection for Neovim
- [schema-companion.nvim](https://github.com/cenk1cenk2/schema-companion.nvim) - Schema companion for various file types

## License

MIT
