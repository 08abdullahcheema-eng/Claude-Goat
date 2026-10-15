# small text snippets for the lock screen
# moon illumination in percent (days since the new moon of 2024-01-11 11:57 UTC)
moon_pct() { awk -v t="$(date +%s)" 'BEGIN { p = ((t - 1704974220) / 86400) / 29.530588853; p -= int(p); printf "%d\n", (1 - cos(2 * 3.14159265 * p)) / 2 * 100 + 0.5 }'; }
# milliseconds since the epoch, for the moving bits of the lock screen
ms() { date +%s%3N; }
case "${1:-status}" in
  clock)
    # HH:MM with a colon that slowly breathes in the given colour (sumi: the red seal)
    c=${2:-#c8323a}
    a=$(awk -v t="$(ms)" 'BEGIN { printf "%d", 30 + 70 * (0.5 + 0.5 * cos(t / 2000 * 3.14159265)) }')
    echo "$(date +%H)<span foreground='$c' alpha='$a%'>:</span>$(date +%M)"
    ;;
  breath)
    # text whose opacity rises and falls like breath, period in ms (kiri: 霧の中)
    awk -v t="$(ms)" -v p="${3:-6000}" -v s="${2:-}" 'BEGIN { a = 25 + 75 * (0.5 + 0.5 * sin(2 * 3.14159265 * t / p)); printf "<span letter_spacing=\"14000\" alpha=\"%d%%\">%s</span>\n", a, s }'
    ;;
  tick)
    # the current minute as a steel hairline: one segment per second (hagane)
    LC_ALL=C awk -v t="$(ms)" 'BEGIN {
      s = (t / 1000) % 60; n = int(s);
      on = ""; off = ""
      for (i = 0; i < 60; i++) { if (i <= n) on = on "\342\224\200"; else off = off "\342\224\200" }
      printf "<span foreground=\"#ffffff\">%s</span><span foreground=\"#ffffff\" alpha=\"18%%\">%s</span>\n", on, off
    }'
    ;;
  wave)
    # a dotted swell rolling along the horizon, drawn with braille dots (iso)
    LC_ALL=C awk -v t="$(ms)" -v n="${2:-56}" 'BEGIN {
      row[0] = 1; row[1] = 2; row[2] = 4; row[3] = 64      # left dot column, top to bottom
      rr[0] = 8; rr[1] = 16; rr[2] = 32; rr[3] = 128       # right dot column
      ph = t / 900; out = ""
      for (c = 0; c < n; c++) {
        b = 0
        for (k = 0; k < 2; k++) {
          x = c * 2 + k
          y = sin(x * 0.21 - ph) * 0.65 + sin(x * 0.07 + ph * 0.6) * 0.35
          r = int((y + 1) / 2 * 3.999); if (r < 0) r = 0; if (r > 3) r = 3
          b += (k == 0) ? row[r] : rr[r]
        }
        out = out sprintf("%c%c%c", 226, 160 + int(b / 64), 128 + b % 64)
      }
      print out
    }'
    ;;
  stars)
    # a few stars that twinkle out of step with each other (summit)
    awk -v t="$(ms)" 'BEGIN {
      split("✦ · ✧ · ✦ · · ✧ · ✦", g, " "); out = ""
      for (i = 1; i <= 10; i++) {
        a = 15 + 85 * (0.5 + 0.5 * sin(t / (900 + i * 237) + i * 1.7))
        out = out sprintf("<span alpha=\"%d%%\">%s</span>      ", a, g[i])
      }
      print out
    }'
    ;;
  nextwall)
    # the theme's wallpapers in turn, a new one every minute (hyprlock crossfades between them)
    dir="${SUMI_SHELL_DIR:-$HOME/.config/quickshell/sumi}/assets/walls"
    mapfile -t w < <(jq -r '.walls[]?' "$HOME/.config/sumi/theme.json" 2>/dev/null)
    if [ "${#w[@]}" -gt 0 ]; then echo "$dir/${w[$(( $(date +%s) / 60 % ${#w[@]} ))]}"; fi
    ;;
  date)
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    months=(JAN FEB MÄR APR MAI JUN JUL AUG SEP OKT NOV DEZ)
    echo "${days[$(date +%w)]} · $(date +%d) ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  kanji)
    k=(日曜日 月曜日 火曜日 水曜日 木曜日 金曜日 土曜日)
    echo "${k[$(date +%w)]}"
    ;;
  vdate)
    # date in kanji, one character per line, for vertical lock screen text
    n=(〇 一 二 三 四 五 六 七 八 九)
    kn() { local v=$1 t=$(( $1 / 10 )) o=$(( $1 % 10 )) r=""; if [ "$v" -lt 10 ]; then r=${n[$o]}; else [ "$t" -gt 1 ] && r=${n[$t]}; r="$r十"; [ "$o" -gt 0 ] && r="$r${n[$o]}"; fi; echo "$r"; }
    k=(日 月 火 水 木 金 土)
    s="$(kn "$(date +%-m)")月$(kn "$(date +%-d)")日 ${k[$(date +%w)]}曜日"
    printf '%s' "$s" | tr -d ' ' | LC_ALL=C.UTF-8 grep -o .
    ;;
  kdate)
    # date in kanji on one line: 十月十二日
    n=(〇 一 二 三 四 五 六 七 八 九)
    kn() { local v=$1 t=$(( $1 / 10 )) o=$(( $1 % 10 )) r=""; if [ "$v" -lt 10 ]; then r=${n[$o]}; else [ "$t" -gt 1 ] && r=${n[$t]}; r="$r十"; [ "$o" -gt 0 ] && r="$r${n[$o]}"; fi; echo "$r"; }
    echo "$(kn "$(date +%-m)")月$(kn "$(date +%-d)")日"
    ;;
  short)
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    echo "${days[$(date +%w)]} $(date +%d.%m)"
    ;;
  long)
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    months=(JANUAR FEBRUAR MÄRZ APRIL MAI JUNI JULI AUGUST SEPTEMBER OKTOBER NOVEMBER DEZEMBER)
    echo "${days[$(date +%w)]} · $(date +%-d). ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  moon)
    moon_pct
    ;;
  roman)
    # SONNTAG · XII · OKTOBER
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    months=(JANUAR FEBRUAR MÄRZ APRIL MAI JUNI JULI AUGUST SEPTEMBER OKTOBER NOVEMBER DEZEMBER)
    r=(I II III IV V VI VII VIII IX X XI XII XIII XIV XV XVI XVII XVIII XIX XX XXI XXII XXIII XXIV XXV XXVI XXVII XXVIII XXIX XXX XXXI)
    echo "${days[$(date +%w)]} · ${r[$(( $(date +%-d) - 1 ))]} · ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  words)
    # Montag, der zwölfte Oktober
    days=(Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag)
    months=(Januar Februar März April Mai Juni Juli August September Oktober November Dezember)
    o=(erste zweite dritte vierte fünfte sechste siebte achte neunte zehnte elfte zwölfte dreizehnte vierzehnte fünfzehnte sechzehnte siebzehnte achtzehnte neunzehnte zwanzigste einundzwanzigste zweiundzwanzigste dreiundzwanzigste vierundzwanzigste fünfundzwanzigste sechsundzwanzigste siebenundzwanzigste achtundzwanzigste neunundzwanzigste dreißigste einunddreißigste)
    echo "${days[$(date +%w)]}, der ${o[$(( $(date +%-d) - 1 ))]} ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  sky)
    # SO 12 OKT · MOND 64 %
    d=(SO MO DI MI DO FR SA); m=(JAN FEB MÄR APR MAI JUN JUL AUG SEP OKT NOV DEZ)
    echo "${d[$(date +%w)]} $(date +%d) ${m[$(( $(date +%-m) - 1 ))]} · MOND $(moon_pct) %"
    ;;
  clockc)
    # HH:MM with a steady colon in the given colour
    echo "$(date +%H)<span foreground='${2:-#c8323a}'>:</span>$(date +%M)"
    ;;
  ldate)
    # DONNERSTAG  ·  15. OKTOBER
    days=(SONNTAG MONTAG DIENSTAG MITTWOCH DONNERSTAG FREITAG SAMSTAG)
    months=(JANUAR FEBRUAR MÄRZ APRIL MAI JUNI JULI AUGUST SEPTEMBER OKTOBER NOVEMBER DEZEMBER)
    echo "${days[$(date +%w)]}  ·  $(date +%-d). ${months[$(( $(date +%-m) - 1 ))]}"
    ;;
  kday)
    # date and weekday in kanji: 十月十五日  木曜日
    k=(日 月 火 水 木 金 土)
    echo "$("$0" kdate)  ${k[$(date +%w)]}曜日"
    ;;
  now)
    # now playing, with a short accent bar in front (empty when nothing plays)
    t=$(playerctl metadata --format '{{title}} · {{artist}}' 2>/dev/null | cut -c1-60 || true)
    if [ -n "$t" ]; then echo "<span foreground='${2:-#c8323a}'>▍</span> $t"; else echo ""; fi
    ;;
  stat2)
    # battery, keyboard layout, network, spaced out
    out=""
    for b in /sys/class/power_supply/BAT*; do
      [ -r "$b/capacity" ] || continue
      cap=$(cat "$b/capacity" || true); st=$(cat "$b/status" 2>/dev/null || true)
      if [ "$st" = "Charging" ]; then out="⚡ $cap %"; else out="$cap %"; fi
      break
    done
    kb=$(hyprctl -j devices 2>/dev/null | jq -r '[.keyboards[] | select(.main)][0].active_keymap // empty' 2>/dev/null || true)
    case "$kb" in German*) kb=DE;; "English (US)"*) kb=US;; "") ;; *) kb=$(echo "$kb" | cut -c1-2 | tr a-z A-Z);; esac
    [ -n "$kb" ] && out="$out     $kb"
    ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1=="yes"{print $2; exit}' || true)
    [ -n "$ssid" ] && out="$out     $ssid"
    echo "$out"
    ;;
  since)
    echo "Passwort eingeben  ·  gesperrt seit $(date +%H:%M)"
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
