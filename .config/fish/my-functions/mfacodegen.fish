function __mfacodegen_load
  set -l dat ~/.mfa/accounts.dat
  set -l key ~/.mfa/mfa.key
  sudo openssl smime -decrypt -binary -inform PEM -in $dat -inkey $key 2> /dev/null
end

function mfacodegen
  # Read accounts
  set -l record
  set -l records
  for record in (__mfacodegen_load)
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
