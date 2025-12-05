#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"

MAX_TIME=2
USER_AGENT="tmux-ip-address"

# mode: public | local (default: public)
MODE=$(get_tmux_option "@ip_address_mode" "public")

is_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
}

fetch_ip() {
  local url="$1"
  curl -4 --silent --fail --max-time "$MAX_TIME" -A "$USER_AGENT" "$url" 2>/dev/null | tr -d ' \t\r\n'
}

print_ip_address() {
  if [[ "$MODE" == "local" ]]; then
    # Prefer the interface that has the default route
    if is_osx; then
      local iface
      iface=$(route get default 2>/dev/null | awk '/interface:/{print $2; exit}')
      iface=${iface:-en0}
      ipconfig getifaddr "$iface" 2>/dev/null && return 0
    else
      ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}' && return 0
      hostname -I 2>/dev/null | awk '{print $1; exit}' && return 0
    fi
    return 1
  fi

  local urls=(
    "https://ipv4.icanhazip.com"
    "https://ifconfig.me/ip"
    "https://ifconfig.co/ip"
  )

  for url in "${urls[@]}"; do
    local ip
    ip=$(fetch_ip "$url")
    if is_ipv4 "$ip"; then
      echo "$ip"
      return 0
    fi
  done

  # If all providers fail, emit nothing so caller can show Offline
  return 1
}

main() {
  print_ip_address
}

main
