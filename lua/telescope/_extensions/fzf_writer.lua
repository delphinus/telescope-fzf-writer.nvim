local Job = require('plenary.job')

local conf = require('telescope.config').values
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local sorters = require('telescope.sorters')

local flatten = vim.tbl_flatten

local minimum_grep_characters = 2
local minimum_files_characters = 0

local use_highlighter = false

return require('telescope').register_extension {
  setup = function(conf)
    if conf.minimum_grep_characters then
      minimum_grep_characters = conf.minimum_grep_characters
    end

    if conf.minimum_files_characters then
      minimum_files_characters = conf.minimum_files_characters
    end

    if conf.use_highlighter ~= nil then
      use_highlighter = conf.use_highlighter
    end
  end,

  exports = {
    grep = function(opts)
      opts = opts or {}

      local live_grepper = finders._new {
        fn_command = function(_, prompt)
          if not prompt or prompt == "" then
            return nil
          end

          if #prompt < minimum_grep_characters then
            return nil
          end

          local rg_args = flatten { conf.vimgrep_arguments, "." }
          table.remove(rg_args, 1)

          return {
            writer = Job:new {
              command = 'rg',
              args = rg_args,
            },

            command = 'fzf',
            args = {'--filter', prompt},
          }
        end,

        entry_maker = make_entry.gen_from_vimgrep(opts),
      }

      pickers.new(opts, {
        prompt_title = 'Fzf Writer: Grep',
        finder = live_grepper,
        previewer = previewers.vimgrep.new(opts),
        sorter = use_highlighter and sorters.highlighter_only(opts),
      }):find()
    end,

    staged_grep = function(opts)
      opts = opts or {}

      local live_grepper = finders._new {
        fn_command = function(_, prompt)
          if #prompt < minimum_grep_characters then
            return nil
          end

          local rg_prompt, fzf_prompt
          if string.find(prompt, "|") then
            rg_prompt  = string.sub(prompt, 1, string.find(prompt, "|") - 1)
            fzf_prompt = string.sub(prompt, string.find(prompt, "|") + 1, #prompt)
          else
            rg_prompt = prompt
            fzf_prompt = ""
          end
          print("fzf_prompt:", fzf_prompt)

          local rg_args = flatten { conf.vimgrep_arguments, rg_prompt, "." }
          table.remove(rg_args, 1)

          return {
            writer = Job:new {
              command = 'rg',
              args = rg_args,
            },

            command = 'fzf',
            args = {'--filter', fzf_prompt},
          }
        end,

        entry_maker = make_entry.gen_from_vimgrep(opts),
      }

      pickers.new(opts, {
        prompt_title = 'Fzf Writer: Grep',
        finder = live_grepper,
        previewer = previewers.vimgrep.new(opts),
        sorter = use_highlighter and sorters.highlighter_only(opts),
      }):find()
    end,

    files = function(opts)
      opts = opts or {}

      local _ = make_entry.gen_from_vimgrep(opts)
      local live_grepper = finders._new {
        fn_command = function(self, prompt)
          if #prompt < minimum_files_characters then
            return nil
          end

          return {
            writer = Job:new {
              command = 'rg',
              args = {"--files"},
            },

            command = 'fzf',
            args = {'--filter', prompt}
          }
        end,

        entry_maker = make_entry.gen_from_file(opts),
      }

      pickers.new(opts, {
        prompt_title = 'Fzf Writer: Files',
        finder = live_grepper,
        previewer = previewers.vimgrep.new(opts),
        sorter = use_highlighter and sorters.highlighter_only(opts),
      }):find()
    end,
  },
}
