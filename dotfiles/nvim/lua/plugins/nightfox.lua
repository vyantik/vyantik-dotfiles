---@type LazySpec
return {
  "EdenEast/nightfox.nvim",
  priority = 1000,
  config = function()
    require("nightfox").setup({
      options = {
        styles = {
          comments = "italic",
          keywords = "bold",
          types = "italic,bold",
        },
        inverse = {
          match_paren = true,
          visual = false,
          search = false,
        },
        terminal_colors = true,
        dim_inactive = false,
        transparent = false,
      },
    })
  end,
}
