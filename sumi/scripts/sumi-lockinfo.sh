# small text snippets for the lock screen
case "${1:-status}" in
  date)
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    months=(JAN FEB MÄR APR MAI JUN JUL AUG SEP OKT NOV DEZ)
    echo "${days[$(date +%w)]} · $(date +%d) ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  kanji)
    k=(日曜日 月曜日 火曜日 水曜日 木曜日 金曜日 土曜日)
    echo "${k[$(date +%w)]}"
    ;;
  music)
    t=$(playerctl metadata --format '{{title}} · {{artist}}' 2>/dev/null | cut -c1-60 || true)
    if [ -n "$t" ]; then echo "♪  $t"; else echo ""; fi
    ;;
  status)
    out=""
    kb=$(hyprctl -j devices 2>/dev/null | jq -r '[.keyboards[] | select(.main)][0].active_keymap // empty' 2>/dev/null || true)
    case "$kb" in German*) kb=DE;; "English (US)"*) kb=US;; "") ;; *) kb=$(echo "$kb" | cut -c1-2 | tr a-z A-Z);; esac
    if [ -n "$kb" ]; then out="$out⌨ $kb    "; fi
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}' || true)
    if [ -n "$ssid" ]; then out="$out$ssid    "; fi
    for b in /sys/class/power_supply/BAT*; do
      [ -r "$b/capacity" ] || continue
      cap=$(cat "$b/capacity" || true); st=$(cat "$b/status" 2>/dev/null || true)
      if [ "$st" = "Charging" ]; then out="$out⚡ $cap%"; else out="$out$cap%"; fi
      break
    done
    echo "$out"
    ;;
esac
