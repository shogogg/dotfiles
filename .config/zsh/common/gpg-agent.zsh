# Since v2.1 GnuPG have changed the method a daemon starts. They are all started
# on demand now. For more information see:
#   https://www.gnupg.org/faq/whats-new-in-2.1.html#autostart
gpgconf --launch gpg-agent

export GPG_TTY=$(/usr/bin/tty)
export SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"
