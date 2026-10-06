#!/etc/profiles/per-user/danil/bin/bash

status=$(protonvpn status 2>&1)

if echo "$status" | grep -q "^Status: Connected"; then
  server=$(echo "$status" | sed -n 's/^Server: //p')
  load=$(echo "$status" | sed -n 's/^Load: //p')
  protocol=$(echo "$status" | sed -n 's/^Protocol: //p')

  protocol="${protocol^}"

  tooltip="Proton VPN: Connected"$'\n'
  tooltip+="Server: ${server}"$'\n'
  tooltip+="Load: ${load}"$'\n'
  tooltip+="Protocol: ${protocol}"

  jq -cn \
    --arg text "󰦝" \
    --arg tooltip "$tooltip" \
    '{text: $text, tooltip: $tooltip, class: "connected"}'
else
  jq -cn \
    --arg text "" \
    --arg tooltip "Proton VPN: Disconnected" \
    '{text: $text, tooltip: $tooltip, class: "disconnected"}'
fi
