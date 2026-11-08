-- Minimale Neovim-Konfiguration (Neovim 0.12)
-- Sprachen: Bash, C/C++, Common Lisp, LaTeX, Lua, Markdown, Python, Rust, SQL
-- Alles Übrige bleibt auf den Neovim-Standardwerten.

-- [[ Build-Schritt: Treesitter-Parser nach Installation/Update neu übersetzen ]]
vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind ~= 'delete' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
    end
  end,
})

-- [[ VimTeX: muss vor dem Laden des Plugins gesetzt sein ]]
vim.g.vimtex_view_general_viewer = 'SumatraPDF'
vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
vim.g.vimtex_quickfix_open_on_warning = 0

-- [[ Plugins ]]
local function gh(repo) return 'https://github.com/' .. repo end
vim.pack.add {
  gh 'neovim/nvim-lspconfig', -- Konfigurationen der Sprachserver
  gh 'mason-org/mason.nvim', -- installiert Sprachserver und Formatter
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim', -- ... automatisch aus einer Liste
  gh 'stevearc/conform.nvim', -- Formatter aufrufen
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' }, -- Parser installieren
  gh 'lervag/vimtex', -- LaTeX
  gh 'MeanderingProgrammer/render-markdown.nvim', -- Markdown-Darstellung im Puffer
}

-- [[ Mason: Werkzeuge (Mason-Paketnamen) ]]
-- rust-analyzer und rustfmt kommen von rustup, latexindent von TeX Live.
require('mason').setup()
require('mason-tool-installer').setup {
  ensure_installed = {
    'bash-language-server', 'shellcheck', 'shfmt', -- Bash
    'clangd', 'clang-format', -- C/C++
    'lua-language-server', 'stylua', -- Lua
    'marksman', -- Markdown
    'basedpyright', 'ruff', -- Python
    'sql-formatter', -- SQL
    'texlab', -- LaTeX
  },
}

-- [[ LSP (lspconfig-Namen) ]]
vim.lsp.config('lua_ls', {
  settings = { Lua = { runtime = { version = 'LuaJIT' }, workspace = { library = { vim.env.VIMRUNTIME } } } },
})
vim.lsp.enable { 'bashls', 'clangd', 'lua_ls', 'marksman', 'basedpyright', 'ruff', 'rust_analyzer', 'texlab' }

vim.diagnostic.config { virtual_text = true } -- Fehlermeldung am Zeilenende (Standard seit 0.11: aus)

-- Eingebaute LSP-Vervollständigung: <C-n>/<C-p> wählen, <C-y> übernehmen
vim.o.completeopt = 'menuone,noselect,popup'
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

-- [[ Formatieren: <leader>f (Standard-Leader ist \) ]]
require('conform').setup {
  formatters_by_ft = {
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    c = { 'clang_format' },
    cpp = { 'clang_format' },
    lua = { 'stylua' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    rust = { 'rustfmt' },
    sql = { 'sql_formatter' },
    tex = { 'latexindent' },
  },
}
vim.keymap.set({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = 'Formatieren' })

-- [[ Treesitter ]]
-- LaTeX bewusst ohne Treesitter: VimTeX übernimmt die Syntax.
require('nvim-treesitter').install { 'bash', 'c', 'commonlisp', 'cpp', 'lua', 'markdown', 'markdown_inline', 'python', 'rust', 'sql' }
vim.treesitter.language.register('commonlisp', 'lisp') -- Vim-Dateityp 'lisp' -> Parser 'commonlisp'
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'sh', 'bash', 'c', 'cpp', 'lisp', 'lua', 'markdown', 'python', 'rust', 'sql' },
  callback = function() pcall(vim.treesitter.start) end,
})

-- [[ Markdown ]]
require('render-markdown').setup {}

-- [[ Persönlich (optional) ]]
vim.cmd.colorscheme 'delek'
