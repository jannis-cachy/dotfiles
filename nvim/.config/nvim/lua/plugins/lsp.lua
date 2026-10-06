return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Mason's own qmlls build is a broken Ubuntu-linked binary (missing libodbc.so.2,
        -- exits 127), use the system one from qt6-declarative instead.
        qmlls = {
          cmd = { "qmlls6" },
          mason = false,
        },
        -- clangd ships with the system already.
        clangd = {
          mason = false,
        },
        -- pyright and ruff need `pyright` and `ruff` installed via pacman: this machine
        -- has no node/pip for Mason to fetch its own copies.
        pyright = {
          mason = false,
        },
        ruff = {
          mason = false,
        },
      },
    },
  },
}
