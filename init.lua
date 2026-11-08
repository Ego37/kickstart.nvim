-- init.lua – kompakte Fassung auf Basis von kickstart.nvim (vim.pack, Neovim >= 0.12)
--
-- Sprachen:   Sprachserver            Formatter               Treesitter
--   Bash      bashls (+ shellcheck)   shfmt                   bash
--   C/C++     clangd                  clang-format            c, cpp
--   Lisp      –                       –                       commonlisp
--   LaTeX     texlab                  latexindent (TeX Live)  – (VimTeX, siehe lua/custom/plugins/latex.lua)
--   Lua       lua_ls                  stylua                  lua, luadoc
--   Markdown  marksman                –                       markdown, markdown_inline (+ render-markdown)
--   Python    basedpyright, ruff      ruff                    python
--   Rust      rust_analyzer (rustup)  rustfmt (rustup)        rust
--   SQL       – (sqls: Sicherheitslücke, sqlls: defekt)      sql-formatter     sql

local function gh(repo) return 'https://github.com/' .. repo end
local map = vim.keymap.set

-- ============================================================
-- 1. OPTIONEN
-- ============================================================
vim.loader.enable()
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- Provider für Remote-Plugins in Python/Node/Perl/Ruby werden nicht benötigt
for _, p in ipairs { 'python3', 'node', 'perl', 'ruby' } do
  vim.g['loaded_' .. p .. '_provider'] = 0
end

for option, value in pairs {
  number = true,
  relativenumber = true,
  mouse = 'a',
  showmode = true,
  breakindent = true,
  undofile = true,
  ignorecase = true,
  smartcase = true,
  signcolumn = 'yes',
  updatetime = 250,
  timeoutlen = 300,
  splitright = true,
  splitbelow = true,
  list = true,
  inccommand = 'split',
  cursorline = true,
  scrolloff = 10,
  confirm = true,
} do
  vim.o[option] = value
end
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end) -- nach dem Start, spart Startzeit

-- ============================================================
-- 2. TASTENKÜRZEL, DIAGNOSE, AUTOCMDS
-- ============================================================
map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
for _, k in ipairs { 'h', 'j', 'k', 'l' } do
  map('n', '<C-' .. k .. '>', '<C-w><C-' .. k .. '>', { desc = 'Move focus to window ' .. k })
end

vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  virtual_text = true,
  virtual_lines = false,
  jump = {
    on_jump = function(_, bufnr) vim.diagnostic.open_float { bufnr = bufnr, scope = 'cursor', focus = false } end,
  },
}

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('user-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- ============================================================
-- 3. PLUGINS: Build-Schritte nach Installation/Update, dann alle Plugins laden
-- ============================================================
local function run_build(name, cmd, cwd)
  local result = vim.system(cmd, { cwd = cwd }):wait()
  if result.code ~= 0 then
    local output = (result.stderr ~= '' and result.stderr) or result.stdout or ''
    vim.notify(('Build failed for %s:\n%s'):format(name, output ~= '' and output or 'No output.'), vim.log.levels.ERROR)
  end
end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= 'install' and kind ~= 'update' then return end
    if name == 'telescope-fzf-native.nvim' and vim.fn.executable 'make' == 1 then
      run_build(name, { 'make' }, ev.data.path)
    elseif name == 'LuaSnip' and vim.fn.has 'win32' ~= 1 and vim.fn.executable 'make' == 1 then
      run_build(name, { 'make', 'install_jsregexp' }, ev.data.path)
    elseif name == 'nvim-treesitter' then
      if not ev.data.active then vim.cmd.packadd 'nvim-treesitter' end
      vim.cmd 'TSUpdate'
    end
  end,
})

---@type (string | vim.pack.Spec)[]
local plugins = {
  -- Oberfläche und Komfort
  gh 'NMAC427/guess-indent.nvim',
  gh 'lewis6991/gitsigns.nvim',
  gh 'folke/which-key.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'nvim-mini/mini.nvim',
  -- Suche
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  -- LSP
  gh 'j-hui/fidget.nvim',
  gh 'neovim/nvim-lspconfig',
  gh 'mason-org/mason.nvim',
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  -- Formatieren, Vervollständigung, Syntax
  gh 'stevearc/conform.nvim',
  { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1.*' },
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },
}
if vim.fn.executable 'make' == 1 then table.insert(plugins, gh 'nvim-telescope/telescope-fzf-native.nvim') end
vim.pack.add(plugins)

-- ============================================================
-- 4. OBERFLÄCHE: Farbschema, gitsigns, which-key, mini
-- ============================================================
vim.cmd.colorscheme 'delek'
require('guess-indent').setup {}
require('todo-comments').setup { signs = false }

local gs = require 'gitsigns'
gs.setup {
  signs = {
    add = { text = '+' }, ---@diagnostic disable-line: missing-fields
    change = { text = '~' }, ---@diagnostic disable-line: missing-fields
    delete = { text = '_' }, ---@diagnostic disable-line: missing-fields
    topdelete = { text = '‾' }, ---@diagnostic disable-line: missing-fields
    changedelete = { text = '~' }, ---@diagnostic disable-line: missing-fields
  },
  on_attach = function(buf)
    local function m(mode, lhs, rhs, desc) map(mode, lhs, rhs, { buffer = buf, desc = desc }) end
    local function hunk_jump(key, dir)
      return function()
        if vim.wo.diff then
          vim.cmd.normal { key, bang = true }
        else
          gs.nav_hunk(dir)
        end
      end
    end
    local function range() return { vim.fn.line '.', vim.fn.line 'v' } end
    m('n', ']c', hunk_jump(']c', 'next'), 'Jump to next git [c]hange')
    m('n', '[c', hunk_jump('[c', 'prev'), 'Jump to previous git [c]hange')
    m('v', '<leader>hs', function() gs.stage_hunk(range()) end, 'git [s]tage hunk')
    m('v', '<leader>hr', function() gs.reset_hunk(range()) end, 'git [r]eset hunk')
    m('n', '<leader>hs', gs.stage_hunk, 'git [s]tage hunk')
    m('n', '<leader>hr', gs.reset_hunk, 'git [r]eset hunk')
    m('n', '<leader>hS', gs.stage_buffer, 'git [S]tage buffer')
    m('n', '<leader>hR', gs.reset_buffer, 'git [R]eset buffer')
    m('n', '<leader>hp', gs.preview_hunk, 'git [p]review hunk')
    m('n', '<leader>hi', gs.preview_hunk_inline, 'git preview hunk [i]nline')
    m('n', '<leader>hb', function() gs.blame_line { full = true } end, 'git [b]lame line')
    m('n', '<leader>hd', gs.diffthis, 'git [d]iff against index')
    m('n', '<leader>hD', function() gs.diffthis '~' end, 'git [D]iff against last commit')
    m('n', '<leader>hQ', function() gs.setqflist 'all' end, 'git hunk [Q]uickfix list (all files)')
    m('n', '<leader>hq', gs.setqflist, 'git hunk [q]uickfix list (this file)')
    m('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle git show [b]lame line')
    m('n', '<leader>tw', gs.toggle_word_diff, '[T]oggle git intra-line [w]ord diff')
    m({ 'o', 'x' }, 'ih', gs.select_hunk, 'text object [i]nside [h]unk')
  end,
}

require('which-key').setup {
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

if vim.g.have_nerd_font then
  require('mini.icons').setup()
  MiniIcons.mock_nvim_web_devicons() -- für Plugins, die nvim-web-devicons erwarten (z. B. Telescope)
end
require('mini.ai').setup { mappings = { around_next = 'aa', inside_next = 'ii' }, n_lines = 500 }
require('mini.surround').setup()
local statusline = require 'mini.statusline'
statusline.setup { use_icons = vim.g.have_nerd_font }
---@diagnostic disable-next-line: duplicate-set-field
statusline.section_location = function() return '%2l:%-2v' end

-- ============================================================
-- 5. SUCHE: Telescope
-- ============================================================
require('telescope').setup {
  extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
}
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

local tb = require 'telescope.builtin'
for _, km in ipairs {
  { 'sh', tb.help_tags, '[S]earch [H]elp' },
  { 'sk', tb.keymaps, '[S]earch [K]eymaps' },
  { 'sf', tb.find_files, '[S]earch [F]iles' },
  { 'ss', tb.builtin, '[S]earch [S]elect Telescope' },
  { 'sw', tb.grep_string, '[S]earch current [W]ord', { 'n', 'v' } },
  { 'sg', tb.live_grep, '[S]earch by [G]rep' },
  { 'sd', tb.diagnostics, '[S]earch [D]iagnostics' },
  { 'sr', tb.resume, '[S]earch [R]esume' },
  { 's.', tb.oldfiles, '[S]earch Recent Files ("." for repeat)' },
  { 'sc', tb.commands, '[S]earch [C]ommands' },
  { '<leader>', tb.buffers, '[ ] Find existing buffers' },
  { '/', function() tb.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false }) end, '[/] Fuzzily search in current buffer' },
  { 's/', function() tb.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' } end, '[S]earch [/] in Open Files' },
  { 'sn', function() tb.find_files { cwd = vim.fn.stdpath 'config', follow = true } end, '[S]earch [N]eovim files' },
} do
  map(km[4] or 'n', '<leader>' .. km[1], km[2], { desc = km[3] })
end

-- ============================================================
-- 6. LSP: Tastenkürzel, Sprachserver, Mason
-- ============================================================
require('fidget').setup {}

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local function m(keys, func, desc, mode) map(mode or 'n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end
    m('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    m('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    m('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    m('grd', tb.lsp_definitions, '[G]oto [D]efinition') -- zurück mit <C-t>
    m('grr', tb.lsp_references, '[G]oto [R]eferences')
    m('gri', tb.lsp_implementations, '[G]oto [I]mplementation')
    m('grt', tb.lsp_type_definitions, '[G]oto [T]ype Definition')
    m('gO', tb.lsp_document_symbols, 'Open Document Symbols')
    m('gW', tb.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    -- Vorkommen des Worts unter dem Cursor hervorheben
    if client:supports_method('textDocument/documentHighlight', event.buf) then
      local hl = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = event.buf, group = hl, callback = vim.lsp.buf.document_highlight })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = event.buf, group = hl, callback = vim.lsp.buf.clear_references })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'user-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client:supports_method('textDocument/inlayHint', event.buf) then
      m('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Sprachserver (lspconfig-Namen); Mason installiert alle Einträge automatisch
---@type table<string, vim.lsp.Config>
local servers = {
  basedpyright = {}, -- Python: Typprüfung
  ruff = {}, -- Python: Linter
  bashls = {}, -- Bash
  clangd = {}, -- C/C++
  marksman = {}, -- Markdown
  texlab = {}, -- LaTeX
  stylua = {}, -- Lua: Formatter
  lua_ls = {
    on_init = function(client)
      client.server_capabilities.documentFormattingProvider = false -- formatiert wird mit stylua
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end
      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = { version = 'LuaJIT', path = { 'lua/?.lua', 'lua/?/init.lua' } },
        workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file('', true) },
      })
    end,
    settings = { Lua = { format = { enable = false } } },
  },
}

require('mason').setup {}
require('mason-lspconfig').setup { automatic_enable = false }

local ensure_installed = vim.tbl_keys(servers)
vim.list_extend(ensure_installed, { 'clang-format', 'shfmt', 'shellcheck', 'sql-formatter' })
require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end
vim.lsp.enable 'rust_analyzer' -- kommt von rustup, nicht von Mason

-- ============================================================
-- 7. FORMATIEREN: conform  (<leader>f)
-- ============================================================
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    local enabled_filetypes = {} -- z. B. { python = true, lua = true }
    if enabled_filetypes[vim.bo[bufnr].filetype] then return { timeout_ms = 500 } end
  end,
  default_format_opts = { lsp_format = 'fallback' },
  formatters_by_ft = {
    bash = { 'shfmt' },
    sh = { 'shfmt' },
    c = { 'clang_format' },
    cpp = { 'clang_format' },
    python = { 'ruff_organize_imports', 'ruff_format' },
    rust = { 'rustfmt' },
    sql = { 'sql_formatter' },
    tex = { 'latexindent' },
  },
}
map({ 'n', 'v' }, '<leader>f', function() require('conform').format { async = true } end, { desc = '[F]ormat buffer' })

-- ============================================================
-- 8. VERVOLLSTÄNDIGUNG: LuaSnip + blink.cmp  (<C-y> übernimmt)
-- ============================================================
require('luasnip').setup {}
require('blink.cmp').setup {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
  sources = { default = { 'lsp', 'path', 'snippets' } },
  snippets = { preset = 'luasnip' },
  fuzzy = { implementation = 'lua' },
  signature = { enabled = true },
}

-- ============================================================
-- 9. TREESITTER
-- ============================================================
local ts = require 'nvim-treesitter'
ts.install { 'bash', 'c', 'cpp', 'commonlisp', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'python', 'query', 'rust', 'sql', 'vim', 'vimdoc' }

local function treesitter_try_attach(buf, language)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.treesitter.language.add(language) then return end
  vim.treesitter.start(buf, language)
  if vim.treesitter.query.get(language, 'indents') then vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()" end
end

local available_parsers = ts.get_available()
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local buf, language = args.buf, vim.treesitter.language.get_lang(args.match)
    if not language or language == 'latex' then return end -- LaTeX: VimTeX übernimmt die Syntax
    if not vim.tbl_contains(ts.get_installed 'parsers', language) and vim.tbl_contains(available_parsers, language) then
      ts.install(language):await(function() treesitter_try_attach(buf, language) end) -- fehlenden Parser nachinstallieren
    else
      treesitter_try_attach(buf, language)
    end
  end,
})

-- ============================================================
-- 10. EIGENE MODULE (lua/custom/plugins/*.lua)
-- ============================================================
require 'custom.plugins.latex' -- VimTeX + SumatraPDF
require 'custom.plugins.markdown' -- render-markdown.nvim

-- vim: ts=2 sts=2 sw=2 et
