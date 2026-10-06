#!/etc/profiles/per-user/danil/bin/bash

# Find the interface currently used for the default IPv4 route.
active_iface=$(ip -4 route show table main default 2>/dev/null |
  awk 'NR==1 {for (i=1; i<=NF; i++) if ($i == "dev") {print $(i+1); exit}}')

# If there is no default route, look for a connected physical interface.
if [[ -z "$active_iface" ]]; then
  for iface_path in /sys/class/net/*; do
    iface=$(basename "$iface_path")

    # Ignore virtual/non-physical interfaces.
    case "$iface" in
    lo | proton* | ipv6leakintrf*)
      continue
      ;;
    esac

    if [[ -f "$iface_path/carrier" ]] &&
      [[ "$(cat "$iface_path/carrier" 2>/dev/null)" == "1" ]]; then
      active_iface="$iface"
      break
    fi
  done
fi

# Nothing connected.
if [[ -z "$active_iface" ]]; then
  jq -cn \
    '{text: "", tooltip: "Network: Disconnected", class: "disconnected"}'
  exit 0
fi

# Get IPv4 address.
ipaddr=$(ip -4 -o addr show dev "$active_iface" scope global 2>/dev/null |
  awk '{print $4}' | head -n1)

# Detect Wi-Fi.
if [[ -d "/sys/class/net/$active_iface/wireless" ]]; then

  # Get the currently connected Wi-Fi network from NetworkManager.
  wifi_info=$(nmcli -t -f IN-USE,SSID,SIGNAL dev wifi 2>/dev/null |
    awk -F: '$1=="*" {print; exit}')

  # Signal is always the final field.
  signal_percent=$(printf '%s\n' "$wifi_info" |
    awk -F: '{print $NF}')

  # Everything between IN-USE and SIGNAL is the SSID.
  ssid=$(printf '%s\n' "$wifi_info" |
    cut -d: -f2- |
    sed 's/:[0-9][0-9]*$//')

  # Pick an icon based on signal strength.
  if [[ -z "$signal_percent" ]]; then
    wifi_icon="󰤯"
    signal_percent="Unknown"
  elif ((signal_percent >= 80)); then
    wifi_icon="󰤨"
  elif ((signal_percent >= 60)); then
    wifi_icon="󰤥"
  elif ((signal_percent >= 40)); then
    wifi_icon="󰤢"
  elif ((signal_percent >= 20)); then
    wifi_icon="󰤟"
  else
    wifi_icon="󰤯"
  fi

  tooltip="Wi-Fi: ${ssid:-Connected}"$'\n'
  tooltip+="Signal: ${signal_percent}%"$'\n'
  tooltip+="Interface: ${active_iface}"$'\n'
  tooltip+="IP: ${ipaddr:-No IP}"

  jq -cn \
    --arg text "${ssid:-Connected} ${wifi_icon}" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: "wifi"}'

else

  tooltip="Ethernet: Connected"$'\n'
  tooltip+="Interface: ${active_iface}"$'\n'
  tooltip+="IP: ${ipaddr:-No IP}"

  jq -cn \
    --arg text "󰈀" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: "ethernet"}'

fi
