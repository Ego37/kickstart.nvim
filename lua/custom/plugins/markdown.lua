-- Markdown: formatierte Darstellung im Puffer

vim.pack.add { 'https://github.com/MeanderingProgrammer/render-markdown.nvim' }

require('render-markdown').setup {
  -- Standard: formatiert im Normal-Modus, im Einfügemodus der Rohtext
  -- render_modes = { 'n', 'c', 't' },
}

vim.keymap.set('n', '<leader>tm', '<cmd>RenderMarkdown toggle<CR>', { desc = '[T]oggle [M]arkdown-Darstellung' })
