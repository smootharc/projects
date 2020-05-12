"set shell=/bin/bash
set encoding=utf8
set aw
set nocp
set hidden
set rnu
set showcmd
"set nu
"set hlsearch
set tabstop=4 shiftwidth=4 expandtab
set listchars=space:ᵕ,eol:¬,tab:»-
"set list
set wildmenu
set path=**
set timeoutlen=2000
syntax on
colorscheme slate
map <Space> <leader>
nnoremap <leader>h Qset list!<CR>visual<CR>
nnoremap <leader>j m`O<ESC>``
nnoremap <leader>k m`o<ESC>``
nnoremap <leader>q :qa!<Return>
nnoremap <leader>u :set rnu!<Return>
nnoremap <leader>n :bn<Return>
inoremap jj <ESC>
"nmap <C-j> :m+<CR>
"nmap <C-k> :m .-2<CR>
"runtime ftplugin/man.vim
"nmap <space> <pagedown>
"nmap <backspace> <pageup>

no <left> <nop>
no <right> <nop>
no <up> <nop>
no <down> <nop>
ino <left> <nop>
ino <right> <nop>
ino <up> <nop>
ino <down> <nop>
