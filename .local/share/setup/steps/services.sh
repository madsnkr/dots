# shellcheck shell=bash
# runit services. runsvdir starts them within a few seconds of being linked

svc dbus elogind udevd \
  NetworkManager openntpd firewalld \
  cronie bluetoothd auditd \
  docker libvirtd virtlogd virtlockd

# True if a syslog daemon is enabled or listening on /dev/log
syslogd() {
  local s
  for s in /etc/runit/runsvdir/default/*; do
    case ${s##*/} in
    socklog* | syslog-ng | rsyslog | metalog) return 0 ;;
    esac
  done
  [[ -S /dev/log ]]
}

# firewalld's default "mixed" log target also writes to the console, so its
# startup messages show up while booting. Without a syslog daemon, log to
# /var/log/firewalld only. Skipped if conf exists, so your own OPTS win
conf=/etc/runit/sv/firewalld/conf
if [[ -d ${conf%/*} && ! -e $conf ]] && ! syslogd; then
  echo 'OPTS="--log-target=file"' | sudo tee "$conf" >/dev/null
  log "Set firewalld to log to /var/log/firewalld only"
  if [[ -e /run/runit/service/firewalld ]]; then
    sudo sv restart firewalld
  fi
fi
