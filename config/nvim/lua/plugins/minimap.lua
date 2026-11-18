-- Minimap: floating buffer overview on the right edge.
local excluded = {
  alpha = true,
  oil = true,
  NvimTree = true,
  aerial = true,
  notify = true,
  toggleterm = true,
  lazy = true,
  help = true,
  qf = true,
}

return {
  'nvim-mini/mini.map',
  version = false,
  event = 'BufReadPost',
  keys = {
    { '<leader>mt', function() require('mini.map').toggle() end, desc = 'Toggle minimap' },
    { '<leader>mo', function() require('mini.map').open() end, desc = 'Open minimap' },
    { '<leader>mc', function() require('mini.map').close() end, desc = 'Close minimap' },
    { '<leader>mf', function() require('mini.map').toggle_focus() end, desc = 'Focus minimap' },
    { '<leader>ms', function() require('mini.map').toggle_side() end, desc = 'Flip minimap side' },
  },
  config = function()
    local map = require('mini.map')

    local integrations = {
      map.gen_integration.builtin_search(),
      map.gen_integration.diagnostic({
        error = 'DiagnosticFloatingError',
        warn = 'DiagnosticFloatingWarn',
        info = 'DiagnosticFloatingInfo',
        hint = 'DiagnosticFloatingHint',
      }),
    }
    local ok, git = pcall(map.gen_integration.gitsigns)
    if ok and git then
      table.insert(integrations, git)
    end

    map.setup({
      integrations = integrations,
      symbols = {
        encode = map.gen_encode_symbols.block('3x2'),
        scroll_line = '█',
        scroll_view = '┃',
      },
      window = {
        side = 'right',
        width = 10,
        winblend = 25,
        focusable = false,
        show_integration_count = true,
        zindex = 10,
      },
    })

    -- Open automatically for real code buffers, not tool/dashboard windows.
    local function maybe_open()
      if vim.g.minimap_disable or vim.bo.buftype ~= '' then
        return
      end
      if excluded[vim.bo.filetype] then
        return
      end
      pcall(map.open)
    end

    vim.defer_fn(maybe_open, 200)
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('KuroMinimap', { clear = true }),
      callback = function()
        vim.defer_fn(maybe_open, 50)
      end,
    })
  end,
}
