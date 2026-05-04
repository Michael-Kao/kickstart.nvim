return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  -- event = {
  --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
  --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
  --   -- refer to `:h file-pattern` for more examples
  --   "BufReadPre path/to/my-vault/*.md",
  --   "BufNewFile path/to/my-vault/*.md",
  -- },
  dependencies = {
    -- Required.
    'nvim-lua/plenary.nvim',

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    legacy_commands = false,

    workspaces = {
      {
        name = 'personal',
        path = '~/vault',
      },
    },

    -- see below for full list of options 👇
    -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      -- Set to false to disable completion.
      nvim_cmp = true,
      -- Trigger completion at 2 chars.
      min_chars = 2,
    },

    callbacks = {
      enter_note = function()
        local api = require 'obsidian.api'

        vim.keymap.set('n', 'gf', function()
          if api.cursor_link() then
            return '<cmd>Obsidian follow_link<cr>'
          end

          return 'gf'
        end, { buffer = true, expr = true, desc = 'Obsidian follow link' })

        vim.keymap.set('n', '<leader>ch', '<cmd>Obsidian toggle_checkbox<cr>', {
          buffer = true,
          desc = 'Obsidian toggle checkbox',
        })
      end,
    },
    -- Optional, if you keep notes in a specific subdirectory of your vault.
    notes_subdir = 'notes',

    -- Where to put new notes. Valid options are
    --  * "current_dir" - put new notes in same directory as the current buffer.
    --  * "notes_subdir" - put new notes in the default notes subdirectory.
    new_notes_location = 'notes_subdir',

    -- Optional, customize how note IDs are generated given an optional title.
    ---@param title string|?
    ---@return string
    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ''
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.time()) .. '-' .. suffix
    end,

    link = {
      -- Preserve the old `wiki_link_func = "use_path_only"` behavior.
      style = function(opts)
        local anchor = ''
        if opts.anchor then
          anchor = opts.anchor.anchor
        elseif opts.block then
          anchor = '#' .. opts.block.id
        end

        return string.format('[[%s%s]]', tostring(opts.path or ''):gsub('%.md$', ''), anchor)
      end,
      format = 'shortest',
    },

    frontmatter = {
      enabled = true,
      ---@return table
      func = function(note)
        -- Ensure tags exist
        note.tags = note.tags or {}

        -- print(vim.inspect(note))
        -- Extract folder name from the note's path
        local folder = note.path.filename:match '.*/(.-)/[^/]+$' -- Gets the last folder in the path
        -- print(folder)

        if folder and note.tags[1] == nil then
          table.insert(note.tags, folder) -- Use folder name as a tag
        elseif folder then
          -- remove templates tags if the folder is not templates
          local tmp = note.tags[1] or ''
          local pattern = '(.*)%s*templates%s*(.*)'
          local _, _, left, right = string.find(tmp, pattern)
          if left and right then
            if left == '' and right == '' then
              tmp = ''
            elseif left == '' then
              tmp = right
            elseif right == '' then
              tmp = left
            else
              tmp = left .. ' ' .. right
            end
          end

          -- adding the folder to the tags
          if string.find(tmp, folder, 1, true) == nil then
            if tmp == '' then
              tmp = folder
            else
              tmp = folder .. ' ' .. tmp
            end
          end

          note.tags[1] = tmp
        end

        -- Add the title of the note as an alias.
        -- if note.title then
        --   note:add_alias(note.title)
        -- end

        -- Adding title to the frontmatter will against the markdown linter rule 025
        -- local m_title = note.path.filename:match '[^/]+$'

        -- local out = { id = note.id, aliases = note.aliases, tags = note.tags }
        local out = { tags = note.tags }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },

    -- Optional, for templates (see below).
    templates = {
      folder = 'templates',
      date_format = '%Y/%m/%d',
      time_format = '%H:%M',
      -- A map for custom variables, the key should be the variable and the value a function
      substitutions = {},
    },

    open = {
      use_advanced_uri = false,
      func = vim.ui.open,
    },

    -- when using :ObsidianSearch/ObsidianTags it opens the picker in a floating window
    -- and you can use the following keys to interact with the picker:
    picker = {
      -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
      name = 'telescope.nvim',
      -- Optional, configure key mappings for the picker. These are the defaults.
      -- Not all pickers support all mappings.
      note_mappings = {
        -- Create a new note from your query.
        new = '<C-x>',
        -- Insert a link to the selected note.
        insert_link = '<C-l>',
      },
      tag_mappings = {
        -- Add tag(s) to current note.
        tag_note = '<C-x>',
        -- Insert a tag at the current location.
        insert_tag = '<C-l>',
      },
    },

    search = {
      sort_by = 'modified',
      sort_reversed = true,
      max_lines = 1000,
    },

    -- Optional, determines how certain commands open notes. The valid options are:
    -- 1. "current" (the default) - to always open in the current window
    -- 2. "vsplit" - to open in a vertical split if there's not already a vertical split
    -- 3. "hsplit" - to open in a horizontal split if there's not already a horizontal split
    open_notes_in = 'vsplit',

    checkbox = {
      order = { ' ', 'x', '>', '~', '!' },
    },

    -- Optional, configure additional syntax highlighting / extmarks.
    -- This requires you have `conceallevel` set to 1 or 2. See `:help conceallevel` for more details.
    ui = {
      enable = true, -- set to false to disable all additional syntax features
      update_debounce = 200, -- update delay after a text change (in milliseconds)
      max_file_length = 5000, -- disable UI features for files with more than this many lines
      -- Use bullet marks for non-checkbox lists.
      bullets = { char = '•', hl_group = 'ObsidianBullet' },
      external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
      -- Replace the above with this if you don't have a patched font:
      -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
      reference_text = { hl_group = 'ObsidianRefText' },
      highlight_text = { hl_group = 'ObsidianHighlightText' },
      tags = { hl_group = 'ObsidianTag' },
      block_ids = { hl_group = 'ObsidianBlockID' },
      hl_groups = {
        -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
        ObsidianTodo = { bold = true, fg = '#f78c6c' },
        ObsidianDone = { bold = true, fg = '#89ddff' },
        ObsidianRightArrow = { bold = true, fg = '#f78c6c' },
        ObsidianTilde = { bold = true, fg = '#ff5370' },
        ObsidianImportant = { bold = true, fg = '#d73128' },
        ObsidianBullet = { bold = true, fg = '#89ddff' },
        ObsidianRefText = { underline = true, fg = '#c792ea' },
        ObsidianExtLinkIcon = { fg = '#c792ea' },
        ObsidianTag = { italic = true, fg = '#89ddff' },
        ObsidianBlockID = { italic = true, fg = '#89ddff' },
        ObsidianHighlightText = { bg = '#75662e' },
      },
    },
  },
}
