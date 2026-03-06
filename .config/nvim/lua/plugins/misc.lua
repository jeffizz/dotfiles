return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    ---@type Flash.Config
    opts = {},
    keys = {
      {
        's',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').jump()
        end,
        desc = 'Flash',
      },
      {
        'S',
        mode = { 'n', 'x', 'o' },
        function()
          require('flash').treesitter()
        end,
        desc = 'Flash Treesitter',
      },
      {
        'r',
        mode = 'o',
        function()
          require('flash').remote()
        end,
        desc = 'Remote Flash',
      },
      {
        'R',
        mode = { 'o', 'x' },
        function()
          require('flash').treesitter_search()
        end,
        desc = 'Treesitter Search',
      },
      {
        '<c-s>',
        mode = { 'c' },
        function()
          require('flash').toggle()
        end,
        desc = 'Toggle Flash Search',
      },
    },
  },

  { 'RaafatTurki/hex.nvim', cond = not vim.g.vscode, opts = {} },

  -- { -- Align Code
  --   'junegunn/vim-easy-align',
  --   config = function()
  --     vim.api.nvim_set_keymap('x', '<Leader>a', '<Plug>(EasyAlign)', { noremap = false, silent = true })
  --     vim.api.nvim_set_keymap('n', '<Leader>a', '<Plug>(EasyAlign)', { noremap = false, silent = true })
  --   end,
  -- },
}
