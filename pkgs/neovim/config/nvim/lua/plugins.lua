return {
  {
    "blink.cmp",
    event = {"InsertEnter", "CmdlineEnter"},
    after = function()
      require("blink.cmp").setup()
    end,
  },
  {
    "noice.nvim",
    event = { "DeferredUIEnter" },
    after = function()
      require("noice").setup({
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      })
    end,
  },
  {
    "snacks.nvim",
    lazy = false,
    after = function()
      require("snacks").setup({
        picker = { enabled = true },
        explorer = { enabled = true },
      })
    end,
    keys = {
      -- Top Pickers & Explorer
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "Smart Find Files" },
      { "<leader>,", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>/", function() Snacks.picker.grep() end, desc = "Grep" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
      { "<leader>n", function() Snacks.picker.notifications() end, desc = "Notification History" },
      { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
      -- find
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Buffers" },
      { "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find Config File" },
      { "<leader>ff", function() Snacks.picker.files() end, desc = "Find Files" },
      { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Git Files" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
      { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent" },
    }
  },
  {
    "which-key.nvim",
    event = { "DeferredUIEnter" },
    after = function()
      require('which-key').setup({
        preset = "helix",
      })
    end
  }
}
