-- LaTeX: VimTeX + SumatraPDF

-- Einstellungen vor dem Laden des Plugins setzen
vim.g.vimtex_view_general_viewer = 'SumatraPDF'
vim.g.vimtex_view_general_options = '-reuse-instance -forward-search @tex @line @pdf'
vim.g.vimtex_quickfix_open_on_warning = 0 -- Fehlerliste nur bei Fehlern öffnen, nicht bei Warnungen

-- Nur bei Tectonic statt latexmk:
-- vim.g.vimtex_compiler_method = 'tectonic'

vim.pack.add { 'https://github.com/lervag/vimtex' }

-- Einstellungen für .tex-Dateien
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'tex',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- Zeilen an Wortgrenzen umbrechen
    vim.opt_local.spell = true
    vim.opt_local.spelllang = { 'de', 'en' }
  end,
})
