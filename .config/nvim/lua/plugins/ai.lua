return {
  'olimorris/codecompanion.nvim',
  cond = not vim.g.vscode,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require('codecompanion').setup {
      interactions = {
        chat = {
          adapter = {
            name = 'gemini',
            model = 'gemini-2.5-flash',
          },
        },
        inline = {
          adapter = {
            name = 'gemini',
            model = 'gemini-2.5-flash',
          },
        },
        agent = {
          adapter = {
            name = 'gemini',
            model = 'gemini-2.5-flash',
          },
        },
      },
      adapters = {
        http = {
          gemini = function()
            return require('codecompanion.adapters').extend('gemini', {
              env = {
                api_key = 'cmd: echo $GEMINI_API_KEY',
              },
              schema = {
                model = {
                  default = 'gemini-2.5-flash',
                },
              },
            })
          end,
        },
      },
      display = {
        chat = {
          window = {
            layout = 'vertical',
            width = 0.3,
          },
        },
      },
    }

    vim.keymap.set({ 'n', 'v' }, '<leader>aa', '<cmd>CodeCompanionChat Toggle<cr>', {
      noremap = true,
      silent = true,
      desc = 'AI Chat',
    })
    vim.keymap.set({ 'n', 'v' }, '<leader>ai', '<cmd>CodeCompanion<cr>', {
      noremap = true,
      silent = true,
      desc = 'AI Inline Edit',
    })
    vim.keymap.set('v', 'aa', '<cmd>CodeCompanionChat Add<cr>', {
      noremap = true,
      silent = true,
      desc = 'Add to AI Chat',
    })
    vim.keymap.set('n', '<LocalLeader>d', function()
      require('codecompanion').prompt 'docs'
    end, { noremap = true, silent = true })

    -- Expand 'cc' into 'CodeCompanion' in the command line
    vim.cmd [[cab cc CodeCompanion]]
  end,
}
