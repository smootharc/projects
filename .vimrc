set nocp
set mouse=a
set rnu
set nu
set showcmd
"set hlsearch
set tabstop=4 shiftwidth=4 expandtab
set listchars=space:ᵕ,eol:¬,tab:»-
set list
set wildmenu
syntax on
colorscheme slate
nnoremap <C-h> Qset list!<CR>visual<CR>
nnoremap - m`O<ESC>``
nnoremap + m`o<ESC>``
"runtime ftplugin/man.vim
"nmap <C-CR> o<Esc>
"nmap <CR> o<Esc>
"nmap <space> <pagedown>
"nmap <backspace> <pageup>