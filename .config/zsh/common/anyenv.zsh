if [ -d ~/.anyenv ]; then
  path=(~/.anyenv/bin(N-/) $path)
  eval "$(anyenv init -)"
fi
