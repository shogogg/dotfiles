function install-php
  set -l php_version $argv[1]

  # bzip2 を使う場合のおまじない
  set -x PHP_RPATHS (brew --prefix bzip2)

  # pcre2.h を参照するために必要
  set -x CPPFLAGS "-isystem $HOMEBREW_PREFIX/include"

  # PHP の configure オプション
  set -x PHP_BUILD_CONFIGURE_OPTS \
    --with-bz2=(brew --prefix bzip2) \
    --with-external-pcre=(brew --prefix pcre2) \
    --with-iconv=(brew --prefix libiconv) \
    --with-password-argon2=(brew --prefix argon2) \
    --with-pear \
    --with-tidy=(brew --prefix tidy-html5) \
    --with-zip

  # インストール
  env \
    CXXFLAGS="-std=c++17 -stdlib=libc++ -DU_USING_ICU_NAMESPACE=1" \
    OPENSSL_CFLAGS="-I$HOMEBREW_PREFIX/opt/openssl@3/include" \
    OPENSSL_LIBS="-L$HOMEBREW_PREFIX/opt/openssl@3/lib -lcrypto -lssl" \
    phpenv install --force $php_version

  # 手順で使った変数をクリーンアップ
  set --erase PHP_RPATHS
  set --erase PHP_BUILD_CONFIGURE_OPTS
  set --erase PHP_BUILD_INSTALL_EXTENSION
end
