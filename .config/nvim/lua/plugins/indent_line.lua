return {
  { -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    cond = not vim.g.vscode,
    -- See `:help ibl`
    main = 'ibl',
    opts = {
      indent = { char = '┊' },
    },
  },
}
