-- CopyFX yank feedback for Neovim.
--
-- On every yank the yanked text is highlighted (in the colour of the `Visual` group) for a moment, and CopyFX is told the exact colour of that
-- highlight. CopyFX then finds the highlight on screen (no mouse needed) and plays the current effect right over the yanked text.
--
-- Install (LazyVim / any config): copy this file to ~/.config/nvim/lua/copyfx.lua and add to init.lua:
--     require("copyfx").setup()
-- Options: require("copyfx").setup({ group = "Visual", timeout = 400, operators = { y = true } })
local M = {}

function M.setup(opts)
  opts = vim.tbl_extend("force", {
    group = "Visual",                  -- highlight group used to mark the yanked text (must have a background colour)
    timeout = 400,                     -- ms the marker stays (the effect repaints it exactly, so it is not noticed)
    operators = { y = true },          -- which operators trigger it (add d = true / c = true to also react to deletes)
    command = { "omarchy-shell", "shell", "summon", "io.github.akton1.copyfx" },
  }, opts or {})
  local ns = vim.api.nvim_create_namespace("copyfx_yank")

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("copyfx_yank", { clear = true }),
    callback = function()
      local ev = vim.v.event
      if not opts.operators[ev.operator] then return end
      local hl = vim.api.nvim_get_hl(0, { name = opts.group, link = false })
      if not hl or not hl.bg then return end
      local buf = vim.api.nvim_get_current_buf()
      local range = vim.hl and vim.hl.range or vim.highlight.range
      pcall(range, buf, ns, opts.group, "'[", "']", { regtype = ev.regtype, inclusive = true, priority = 300 })
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
      end, opts.timeout)
      -- the yanked text goes through a private file, never through a process argument
      local dir = os.getenv("XDG_RUNTIME_DIR")
      if not dir or dir == "" then return end
      local path = dir .. "/copyfx-yank.txt"
      local f = io.open(path .. ".new", "w")
      if not f then return end
      f:write((table.concat(ev.regcontents, "\n"):sub(1, 100000)))
      f:close()
      os.rename(path .. ".new", path)
      local payload = vim.json.encode({ yank = { hl = string.format("#%06x", hl.bg), file = true } })
      local cmd = vim.deepcopy(opts.command)
      table.insert(cmd, payload)
      pcall(vim.system, cmd, { detach = true })
    end,
  })
end

return M
