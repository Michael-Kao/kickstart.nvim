-- For `plugins/markview.lua` users.
return {
  'OXY2DEV/markview.nvim',
  lazy = false,
  opts = {
    preview = {
      enable = false,
    },
  },
  keys = {
    { '<leader>mt', '<cmd>Markview toggle<cr>', desc = '[M]arkview [T]oggle preview' },
  },

  -- Completion for `blink.cmp`
  -- dependencies = { "saghen/blink.cmp" },
}
