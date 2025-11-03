# telescope-grep-vibes.nvim

A custom Telescope live grep picker with path scoping and search history that remembers your preferred search directories per project and good vibes! ✨

## ✨ Features

- 🔍 **Live grep** with instant results as you type
- 📁 **Path scoping** - narrow searches to specific directories with `<C-p>`
- 📚 **Search history** - recall previous searches with `<C-j/k>`
- 💾 **Persistent path memory** - remembers your preferred search directory per project
- ⚡ **Fast directory traversal** using `fd`
- 🎯 **50/50 split** between results and preview
- 🔄 **Query preservation** when changing directories
- 🚫 Excludes `.git` and `node_modules` by default
- 👁️ Searches hidden files

## 📦 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'ALPHAvibe/telescope-grep-vibes.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  config = function()
    require('telescope').load_extension('grep_vibes')
  end,
  keys = {
    {
      '<leader>fw',
      '<cmd>Telescope grep_vibes<cr>',
      desc = 'Live Grep (Vibes)'
    },
  },
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'ALPHAvibe/telescope-grep-vibes.nvim',
  requires = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
  },
  config = function()
    require('telescope').load_extension('grep_vibes')
    vim.keymap.set('n', '<leader>fw', '<cmd>Telescope grep_vibes<cr>', { desc = 'Live Grep (Vibes)' })
  end
}
```

## 🚀 Usage

### Basic Usage

There are three ways to open the live grep picker:

1. **Command**: `:Telescope grep_vibes`
2. **Keybinding**: Press `<leader>fw` (if configured)
3. **Lua**: `require('telescope').extensions.grep_vibes.live_grep()`

### Keymaps

| Mode | Key | Action |
|------|-----|--------|
| Insert/Normal | `<C-p>` | Open path picker to scope search to a directory |
| Insert/Normal | `<C-j>` or `<C-k>` | Open search history |
| Insert/Normal | `<Esc>` | Go back (from history to grep) |
| Insert/Normal | `<Enter>` | Open file at matching line |

### Path Scoping Workflow

1. Press `<leader>fw` to open live grep
2. Press `<C-p>` to open the path picker
3. Select a directory to scope your search
4. The plugin remembers your choice for this project!
5. Select `[RESET] . (root)` to clear and search from project root

### Search History

1. Press `<C-j>` or `<C-k>` to view your last 50 searches
2. Select a search to run it again
3. Press `<Esc>` to go back without selecting

## 📝 Requirements

- [fd](https://github.com/sharkdp/fd) - For fast directory traversal
- [ripgrep](https://github.com/BurntSushi/ripgrep) - For fast text searching (required by Telescope's live_grep)
- Neovim >= 0.9.0

## 🎨 Snacks Dashboard Integration

If you use [snacks.nvim](https://github.com/folke/snacks.nvim) dashboard:

```lua
{
    icon = " ",
    key = "W",
    desc = "Live Grep",
    action = function()
        require('telescope').load_extension('grep_vibes')
        require('telescope').extensions.grep_vibes.live_grep()
    end,
},
```

## ⚙️ Configuration

### Custom Keybinding

```lua
{
  'ALPHAvibe/telescope-grep-vibes.nvim',
  config = function()
    require('telescope').load_extension('grep_vibes')
  end,
  keys = {
    { '<leader>sg', '<cmd>Telescope grep_vibes<cr>', desc = 'Search Grep' },
  },
}
```

### Custom Options

You can pass options to the extension:

```lua
require('telescope').extensions.grep_vibes.live_grep({
  cwd = vim.fn.expand('~/projects/my-project'),  -- Set a specific directory
  default_text = 'TODO',                          -- Pre-fill search query
})
```

## 💡 Tips

- The plugin saves your path selections per working directory - great for monorepos!
- Search history persists across Neovim sessions
- Use `<C-p>` while typing to change scope without losing your query
- Press `<Esc>` in history to go back instead of closing everything

## 🗂️ Data Storage

Plugin data is stored at:
- `~/.local/share/nvim/telescope_grep_vibes_history.json`

This file contains both your search history and path preferences per project.


## 🙏 Acknowledgments

Built with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
