function __mfacodegen_load
  set -l dat $argv[1]
  set -l key $argv[2]
  sudo openssl smime -decrypt -binary -inform PEM -in $dat -inkey $key 2> /dev/null
end

function __mfacodegen_edit
  set -l dat $argv[1]
  set -l key $argv[2]
  set -l crt ~/.mfa/mfa.crt
  set -l outfile (sudo mktemp)

  # Remove outfile before exit
  function __mfacodegen_edit_exit --on-job-exit %self --inherit-variable outfile
    functions -e __mfacodegen_edit_exit
    sudo rm -rf $outfile
  end

  sudo openssl smime -decrypt -binary -inform PEM -in $dat -inkey $key -out $outfile 2> /dev/null
  sudo cat $outfile
  sudo vi $outfile
  sudo openssl smime -encrypt -aes256 -in $outfile -out $dat -binary -outform PEM $crt
end

function __mfacodegen_read
  # Read accounts
  set -l record
  set -l records
  set -l dat $argv[1]
  set -l key $argv[2]
  for record in (__mfacodegen_load $dat $key)
    set --append records $record
  end
  if test $status -ne 0
    echo "Failed to load accounts"
    return 1
  end

  # Select account by fzf
  set -l selected (string join \n $records | awk -F '::' '{ print $1 }' | cat -n | fzf)
  if test -z "$selected"
    echo "Account not selected"
    return 1
  end

  # Get selected account index
  set -l index (echo "$selected" | awk '{ print $1 }')

  # Get selected account secret
  set -l key (echo "$records[$index]" | awk -F '::' '{ print $2 }')

  # Get totp token
  set -l token (oathtool -b --totp $key)

  # Display totp token
  echo "$token"

  # Copy totp token to clipboard
  type -q pbcopy && echo -n "$token" | pbcopy
end

function mfacodegen
  set -l dat ~/.mfa/accounts.dat
  set -l key ~/.mfa/mfa.key
  switch $argv[1]
    case edit
      __mfacodegen_edit $dat $key
    case '*'
      __mfacodegen_read $dat $key
  end
end
