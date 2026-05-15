return {
  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    config = function()
      local treesitter = require 'nvim-treesitter'
      local ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

      vim.g.clangd_original_cc = vim.g.clangd_original_cc or vim.env.CC
      vim.g.clangd_original_cxx = vim.g.clangd_original_cxx or vim.env.CXX

      -- Tree-sitter parsers are native Neovim plugins, so they must be built
      -- with the host compiler. This prevents OpenBMC cross-compiler
      -- environments from breaking parser installation with flags like -m64.
      local host_cc = vim.fn.exepath 'gcc'
      local host_cxx = vim.fn.exepath 'g++'
      if host_cc ~= '' then
        vim.env.CC = host_cc
      end
      if host_cxx ~= '' then
        vim.env.CXX = host_cxx
      end

      treesitter.setup()
      treesitter.install(ensure_installed)

      ---@param buf integer
      ---@param language string
      local function treesitter_try_attach(buf, language)
        -- Check if a parser exists and load it.
        if not vim.treesitter.language.add(language) then
          return
        end

        vim.treesitter.start(buf, language)

        -- Enable Treesitter based folds.
        local win = vim.fn.bufwinid(buf)
        if win ~= -1 then
          vim.api.nvim_win_call(win, function()
            vim.wo.foldmethod = 'expr'
            vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            vim.wo.foldlevel = 99
          end)
        end

        -- Enable Treesitter indentation only when this language has an indent query.
        if vim.treesitter.query.get(language, 'indents') then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local language = vim.treesitter.language.get_lang(args.match)
          if not language then
            return
          end

          local installed_parsers = treesitter.get_installed 'parsers'
          if vim.tbl_contains(installed_parsers, language) then
            treesitter_try_attach(args.buf, language)
          end
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },
}
