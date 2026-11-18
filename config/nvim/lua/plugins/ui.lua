-- Visual interface: statusline, tabline, indent guides, notifications,
-- scrollbar and a start screen.
return {
  {
    'nvim-tree/nvim-web-devicons',
    lazy = true,
  },

  -- Sidebar file explorer
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = { 'NvimTreeToggle', 'NvimTreeFindFile' },
    keys = {
      { '<leader>e', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle sidebar explorer' },
      { '<leader>ef', '<cmd>NvimTreeFindFile<cr>', desc = 'Reveal current file' },
    },
    opts = {
      hijack_netrw = true,
      respect_buf_cwd = true,
      update_cwd = true,
      sync_root_with_cwd = true,
      view = {
        width = 34,
        side = 'left',
        number = false,
        relativenumber = false,
        signcolumn = 'no',
        preserve_window_proportions = true,
      },
      renderer = {
        group_empty = true,
        highlight_git = true,
        highlight_opened_files = 'name',
        highlight_modified = 'all',
        root_folder_label = false,
        hidden_display = 'all',
        indent_markers = {
          enable = true,
          inline_arrows = false,
          icons = { corner = '└', edge = '│', item = '├', bottom = '─', none = ' ' },
        },
        icons = {
          show = { git = true, folder = true, file = true, folder_arrow = false, modified = true },
          webdev_colors = true,
          padding = { icon = '   ', folder_arrow = '  ' },
          glyphs = {
            default = '',
            symlink = '',
            modified = '●',
            folder = { arrow_closed = '▸', arrow_open = '▾', default = '', open = '', empty = '', empty_open = '', symlink = '' },
            git = {
              unstaged = '~',
              staged = '+',
              unmerged = '≡',
              renamed = '➜',
              deleted = '✗',
              untracked = '?',
              ignored = '◌',
            },
          },
        },
      },
      diagnostics = {
        enable = true,
        icons = { hint = '', info = '', warning = '', error = '' },
      },
      update_focused_file = { enable = true, update_cwd = true },
      modified = { enable = true, show_on_dirs = true },
      git = { enable = true, ignore = false, timeout = 300 },
      filters = { dotfiles = false, git_ignored = false },
      live_filter = { prefix = ' Filter: ', always_show_folders = false },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
          window_picker = { enable = true },
        },
      },
    },
    config = function(_, opts)
      require('nvim-tree').setup(opts)
      -- nvim-tree has no left-padding option; its sign column shares the tree
      -- background, so reserve two columns for a seamless left gutter.
      require('nvim-tree.api').events.subscribe('TreeOpen', function()
        if vim.bo.filetype == 'NvimTree' then
          vim.wo.signcolumn = 'yes:2'
          vim.wo.cursorline = false
          vim.wo.cursorcolumn = false
        end
      end)
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = function()
      local function lsp_clients()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then
          return ''
        end
        local names = {}
        for _, client in ipairs(clients) do
          names[#names + 1] = client.name
        end
        return ' ' .. table.concat(names, ', ')
      end

      -- Lualine re-evaluates a function theme on every ColorScheme event, so
      -- the modeline follows the active Kuro palette completely.
      local function brighten(hex, amount)
        local h = (hex or ''):gsub('#', '')
        if #h == 3 then
          h = h:gsub('(.)(.)(.)', '%1%1%2%2%3%3')
        end
        if #h ~= 6 then
          return hex
        end
        local function mix(pair)
          local value = tonumber(pair, 16) or 0
          return math.floor(value + (255 - value) * amount + 0.5)
        end
        return string.format('#%02x%02x%02x', mix(h:sub(1, 2)), mix(h:sub(3, 4)), mix(h:sub(5, 6)))
      end

      local function palette_theme()
        local p = require('kuro-themes').palette()
        local function hl(fg, bg, gui)
          return { fg = fg, bg = bg, gui = gui }
        end
        -- The bar sits a shade above the editor background, never exactly on it.
        local base = brighten(p.dark_background, 0.06)
        local mid = brighten(p.background, 0.10)
        local fore = p.foreground
        local function mode(accent)
          return {
            a = hl(base, accent, 'bold'),
            b = hl(fore, base),
            c = hl(fore, mid),
          }
        end
        return {
          normal = mode(p.accent),
          insert = mode(p.green),
          visual = mode(p.magenta),
          replace = mode(p.red),
          command = mode(p.yellow),
          terminal = mode(p.cyan),
          inactive = {
            a = hl(p.muted, base),
            b = hl(p.muted, base),
            c = hl(p.muted, mid),
          },
        }
      end

      return {
        options = {
          theme = palette_theme,
          globalstatus = true,
          component_separators = { left = '│', right = '│' },
          section_separators = { left = '', right = '' },
          disabled_filetypes = { statusline = { 'alpha', 'notify' } },
        },
        sections = {
          lualine_a = {
            {
              'mode',
              fmt = function(str)
                return str:sub(1, 1) .. str:sub(2):lower()
              end,
            },
          },
          lualine_b = {
            { 'branch', icon = '' },
            'diff',
          },
          lualine_c = {
            {
              'filename',
              path = 1,
              file_status = true,
              symbols = { modified = '●', readonly = '🔒', unnamed = '[No Name]' },
            },
          },
          lualine_x = {
            {
              'diagnostics',
              sources = { 'nvim_diagnostic' },
              symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            },
            'searchcount',
            lsp_clients,
            { 'filetype', icon_only = false },
          },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'location' },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },

  -- Tabline
  {
    'akinsho/bufferline.nvim',
    version = '*',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = {
        mode = 'buffers',
        numbers = 'none',
        diagnostics = 'nvim_lsp',
        show_buffer_close_icons = true,
        show_close_icon = false,
        color_icons = true,
        separator_style = 'thin',
        always_show_bufferline = true,
        indicator = { icon = '▎', style = 'underline' },
        modified_icon = '●',
        offsets = {
          {
            filetype = 'NvimTree',
            text = '',
            text_align = 'left',
            highlight = 'BufferLineExplorerOffset',
            separator = true,
          },
          { filetype = 'aerial', text = ' OUTLINE ', highlight = 'Directory', separator = true },
        },
      },
    },
  },

  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│', smart_indent_cap = true },
      scope = { enabled = true, char = '│' },
      exclude = {
        filetypes = { 'help', 'alpha', 'notify', 'oil', 'terminal', 'lazy', 'diffview' },
      },
    },
  },

  -- Notifications
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    opts = {
      stages = 'fade_in_slide_out',
      timeout = 3000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.4)
      end,
      background_colour = 'NormalFloat',
    },
    config = function(_, opts)
      local notify = require('notify')
      notify.setup(opts)
      vim.notify = notify
    end,
  },

  -- Scrollbar (v2: native search marks, no hlslens needed)
  {
    'petertriho/nvim-scrollbar',
    event = 'VeryLazy',
    opts = {
      exclude = {
        buftypes = { terminal = true },
        filetypes = { NvimTree = true, alpha = true, notify = true, oil = true },
      },
      providers = {
        gitsigns = true,
      },
      scrollbar = {
        preset = 'minimal',
        autohide = true,
        thumb = { text = '█', blend = 20 },
      },
    },
  },

  -- Start screen
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')

      dashboard.section.header.val = {
        '   ███╗   ██╗ ███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗',
        '   ████╗  ██║ ██╔════╝██╔═══██╗██║   ██║██║████╗ ████║',
        '   ██╔██╗ ██║ █████╗  ██║   ██║██║   ██║██║██╔████╔██║',
        '   ██║╚██╗██║ ██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║',
        '   ██║ ╚████║ ███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║',
        '   ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝',
      }
      dashboard.section.header.opts.hl = 'AlphaHeader'

      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
        dashboard.button('r', '  Recent files', ':Telescope oldfiles<CR>'),
        dashboard.button('g', '  Live grep', ':Telescope live_grep<CR>'),
        dashboard.button('n', '  New file', ':enew<CR>'),
        dashboard.button('t', '  Change theme', ':KuroTheme<CR>'),
        dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
      }
      dashboard.section.buttons.opts.hl = 'AlphaButtons'

      dashboard.section.footer.opts.hl = 'AlphaFooter'
      dashboard.section.footer.val = '  ' .. vim.fn.hostname() .. ' · ' .. os.date('%a %d %b')

      alpha.setup(dashboard.opts)
    end,
  },
}
