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
"   キーバインド
" ==============================================
noremap A $a
noremap I ^i
noremap == gg=G''
nnoremap j gj
nnoremap k gk
inoremap <silent> jj <ESC>

" ==============================================
"   dein.vim
" ==============================================
let s:dein_dir = expand('~/.vim/dein')
let s:dein_toml = '~/.vim/dein.toml'
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)
  call dein#load_toml(s:dein_toml, {'lazy': 0})
  call dein#end()
  call dein#save_state()
endif

if dein#check_install()
  call dein#install()
endif

" ==============================================
"   Others
" ==============================================
" ファイルタイプ関連を有効にする
filetype plugin indent on

" Syntax Highligt を有効にする
syntax on
