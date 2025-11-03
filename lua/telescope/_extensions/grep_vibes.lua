-- lua/telescope/_extensions/grep_vibes.lua
-- A Telescope extension for live grep with path scoping and search history

local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('telescope-grep-vibes.nvim requires telescope.nvim')
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- History management
local search_history = {}
local path_by_pwd = {}
local MAX_HISTORY = 50
local history_file = vim.fn.stdpath("data") .. "/telescope_grep_vibes_history.json"

-- Load history and path data from disk
local function load_history()
  local f = io.open(history_file, "r")
  if f then
    local content = f:read("*all")
    f:close()
    local ok, decoded = pcall(vim.json.decode, content)
    if ok and type(decoded) == "table" then
      -- Load search history
      if decoded.search_history and type(decoded.search_history) == "table" then
        search_history = decoded.search_history
        -- Ensure we don't exceed max on load
        while #search_history > MAX_HISTORY do
          table.remove(search_history)
        end
      end

      -- Load path selections
      if decoded.path_by_pwd and type(decoded.path_by_pwd) == "table" then
        path_by_pwd = decoded.path_by_pwd
      end
    end
  end
end

-- Save history and path data to disk
local function save_history()
  local f = io.open(history_file, "w")
  if f then
    local data = {
      search_history = search_history,
      path_by_pwd = path_by_pwd,
    }
    f:write(vim.json.encode(data))
    f:close()
  end
end

-- Add search query to history
local function add_to_history(query)
  -- Don't add empty queries
  if query == nil or query == "" then
    return
  end

  -- Remove if already exists
  for i, search in ipairs(search_history) do
    if search == query then
      table.remove(search_history, i)
      break
    end
  end

  -- Add to front
  table.insert(search_history, 1, query)

  -- Trim to max size
  while #search_history > MAX_HISTORY do
    table.remove(search_history)
  end

  -- Persist to disk
  save_history()
end

-- Initialize history on module load
load_history()

-- Show search history picker
local function show_history(current_picker, opts, live_grep_fn)
  if #search_history == 0 then
    vim.notify("No search history available", vim.log.levels.INFO)
    return
  end

  local history_picker = pickers.new({}, {
    prompt_title = "Search History (Last 50) | <Enter> Search Again | <Esc> Go Back",
    finder = finders.new_table({
      results = search_history,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          -- Launch new grep with selected query
          live_grep_fn({
            cwd = opts.cwd,
            default_text = selection.value,
          })
        end
      end)

      -- Esc: Go back to live grep
      map("i", "<Esc>", function()
        actions.close(prompt_bufnr)
        live_grep_fn({ cwd = opts.cwd })
      end)

      map("n", "<Esc>", function()
        actions.close(prompt_bufnr)
        live_grep_fn({ cwd = opts.cwd })
      end)

      return true
    end,
  })

  -- Close current picker and open history
  actions.close(current_picker)
  history_picker:find()
end

-- Show path picker to select search scope
local function show_path_picker(current_picker, current_query, live_grep_fn)
  local Path = require("plenary.path")

  -- Get all directories from current working directory using fd for better performance
  local cwd = vim.loop.cwd()

  -- Get directories using fd
  local handle = io.popen('fd --type d --hidden --exclude .git --exclude node_modules . "' .. cwd .. '"')
  local result = handle:read("*a")
  handle:close()

  -- Parse directories into table
  local dirs = {}
  for dir in result:gmatch("[^\r\n]+") do
    table.insert(dirs, dir)
  end

  -- Prepend reset option at the beginning
  table.insert(dirs, 1, cwd)

  local path_picker = pickers.new({}, {
    prompt_title = "Select Path to Search | Fuzzy search enabled | <Enter> Select",
    finder = finders.new_table({
      results = dirs,
      entry_maker = function(entry)
        local relative = Path:new(entry):make_relative(cwd)
        local display

        -- Special display for root/reset option
        if entry == cwd then
          display = "[RESET] . (root)"
        else
          display = relative == "" and "." or relative
        end

        return {
          value = entry,
          display = display,
          ordinal = relative,
          path = entry,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selection then
          local root_cwd = vim.loop.cwd()

          -- If selecting root/reset, clear saved path
          if selection.value == root_cwd then
            path_by_pwd[root_cwd] = nil
          else
            -- Save path selection for current pwd
            path_by_pwd[root_cwd] = selection.value
          end

          -- Persist to disk
          save_history()

          -- Launch new grep scoped to selected path, preserving current query
          live_grep_fn({
            cwd = selection.value,
            default_text = current_query,
          })
        end
      end)
      return true
    end,
  })

  -- Close current picker and open path picker
  actions.close(current_picker)
  path_picker:find()
end

-- Main live grep function
local function live_grep(opts)
  opts = opts or {}

  -- Check for saved path for current pwd if cwd not explicitly provided
  local root_cwd = vim.loop.cwd()
  if not opts.cwd and path_by_pwd[root_cwd] then
    opts.cwd = path_by_pwd[root_cwd]
  else
    opts.cwd = opts.cwd or root_cwd
  end

  local title = "Live Grep | <C-p> Path | <C-j/k> History"
  if opts.cwd ~= root_cwd then
    local Path = require("plenary.path")
    local relative = Path:new(opts.cwd):make_relative(root_cwd)
    title = "Live Grep [" .. (relative == "" and "." or relative) .. "] | <C-p> Path | <C-j/k> History"
  end

  -- Use telescope's built-in live_grep with our custom mappings
  local builtin = require('telescope.builtin')

  builtin.live_grep({
    prompt_title = title,
    cwd = opts.cwd,
    default_text = opts.default_text,
    additional_args = function()
      return { "--hidden", "--glob", "!.git/*", "--glob", "!node_modules/*" }
    end,
    layout_config = {
      horizontal = {
        preview_width = 0.5,
      },
      vertical = {
        preview_height = 0.5,
      },
    },
    attach_mappings = function(prompt_bufnr, map)
      -- Default action: open file and add search query to history
      actions.select_default:replace(function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local current_query = picker:_get_prompt()

        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        -- Add query to history
        add_to_history(current_query)

        if selection then
          -- Open the file at the matching line
          vim.cmd(string.format("edit +%d %s", selection.lnum, vim.fn.fnameescape(selection.filename)))
        end
      end)

      -- Ctrl+p: Open path picker (preserve current query)
      map("i", "<C-p>", function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local current_query = picker:_get_prompt()
        show_path_picker(prompt_bufnr, current_query, live_grep)
      end)

      map("n", "<C-p>", function()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local current_query = picker:_get_prompt()
        show_path_picker(prompt_bufnr, current_query, live_grep)
      end)

      -- Ctrl+j/k: Show history
      map("i", "<C-j>", function()
        show_history(prompt_bufnr, { cwd = opts.cwd }, live_grep)
      end)

      map("n", "<C-j>", function()
        show_history(prompt_bufnr, { cwd = opts.cwd }, live_grep)
      end)

      map("i", "<C-k>", function()
        show_history(prompt_bufnr, { cwd = opts.cwd }, live_grep)
      end)

      map("n", "<C-k>", function()
        show_history(prompt_bufnr, { cwd = opts.cwd }, live_grep)
      end)

      return true
    end,
  })
end

-- Register the extension
return telescope.register_extension({
  exports = {
    grep_vibes = live_grep,
    live_grep = live_grep,
  },
})
