return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      image = {
        enabled = true,
        resolve = function(path, src)
          local ok, api = pcall(require, 'obsidian.api')
          if ok and api.path_is_note(path) then
            return api.resolve_attachment_path(src)
          end
        end,
      },
    },
  },
}
