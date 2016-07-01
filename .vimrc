" 一旦ファイルタイプ関連を無効化する
filetype off
filetype plugin indent off

" ==============================================
"   カラースキーマ
" ==============================================
colorscheme molokai

" ==============================================
"   基本的な設定
" ==============================================
set nocompatible   " vi 互換モードをOFF
set encoding=utf-8 nobomb
scriptencoding utf-8

" ==============================================
"   表示関連
" ==============================================
set nonumber       " 画面左に行番号を表示しない
set ruler          " ステータスラインに行・列を表示する

" ==============================================
"   タブ・インデント関連
" ==============================================
set autoindent
set smartindent
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2

" ==============================================
"   検索関連
" ==============================================
set incsearch      " インクリメンタル検索を有効にする
set hlsearch       " 検索結果をハイライトする
set ignorecase     " 小文字のみの検索では大文字・小文字を無視する
set smartcase      " 大文字を含む検索では大文字・小文字を判別する

" ==============================================
"   NeoBundle
" ==============================================
if has('vim_starting')
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif
call neobundle#begin(expand('~/.vim/bundle/'))
NeoBundleFetch 'Shougo/neobundle.vim'
call neobundle#end()

" ==============================================
"   vimproc
" ==============================================
NeoBundle 'Shougo/vimproc', {
  \ 'build': {
  \   'windows': 'make -f make_mingw32.mak',
  \   'cygwin':  'make -f make_cygwin.mak',
  \   'mac':     'make -f make_mac.mak',
  \   'unix':    'make -f make_unix.mak',
  \   },
  \ }

" ==============================================
"   lightline
" ==============================================
NeoBundle 'itchyny/lightline.vim'
set laststatus=2
let g:lightline = {
  \   'colorscheme': 'wombat',
  \   'component': {
  \     'readonly': '%{&readonly?"READ ONLY":""}'
  \   }
  \ }
if !has('gui_running')
  set t_Co=256
endif

" ==============================================
"   unite
" ==============================================
NeoBundle 'Shougo/unite.vim'

" ==============================================
"   Others
" ==============================================
NeoBundle 'derekwyatt/vim-scala'
NeoBundle 'vim-ruby/vim-ruby'
NeoBundle 'mattn/emmet-vim'
NeoBundle 'kchmck/vim-coffee-script'
NeoBundle 'groenewege/vim-less'

" Installation check.
NeoBundleCheck

" ファイルタイプ関連を有効にする
filetype plugin indent on

" Syntax Highligt を有効にする
syntax on

