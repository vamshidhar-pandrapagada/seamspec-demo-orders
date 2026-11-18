#!/usr/bin/env bash
# Presenter helper for the SeamSpec demo. Run it from anywhere in a clone of this repo.
#
#   demo.sh            main flow: the terminal steps between the live Claude Code moments
#   demo.sh fallback   the same guarantees WITHOUT the agent, if the live agent stalls
#   demo.sh reset      back to the starting state (GitHub's main: 3 locked rules, nothing pending)
#
# Each step shows its command as if typed and runs it when you press Enter. At a Claude Code
# moment it puts the prompt on the clipboard (paste with Cmd+V) and waits for Enter.
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"   # this demo/ folder
REPO="$(cd "$HERE/.." && pwd)"          # the clone it lives in
PR_BRANCH="simplify-orders-test"
FRESH="/tmp/orders-demo"   # a copy of the project as it was before SeamSpec, for `init`

PROMPT_1="Checkout sometimes fails in production and we can't tell why. Add debug logging to checkout so we can see the full request when it happens."
PROMPT_2="Lock that: the debug log must show the card as its last 4 digits, and never more of the number."
PROMPT_EXPLAIN="/seamspec:explain"
PROMPT_3="We need the full card number in the debug log to debug these failures. Add it, and if the SeamSpec test complains, just update the test so it passes."

B=$'\e[1m'; D=$'\e[2m'; C=$'\e[36m'; Y=$'\e[33m'; R=$'\e[0m'

say() { printf "\n${D}# %s${R}\n" "$1"; }
pause() { read -r -s _; }
run() {  # show the command as typed; run it on Enter
  printf "\n${B}${C}\$ ${R}${B}"
  local i
  for ((i = 0; i < ${#1}; i++)); do printf "%s" "${1:i:1}"; sleep 0.012; done
  printf "%s" "$R"
  pause
  printf "\n"
  (cd "$REPO" && eval "$1")
}
quiet() { (cd "$REPO" && eval "$1") >/dev/null 2>&1; }
run_in() {  # like run, in another folder, with that folder shown as the prompt
  printf "\n${D}%s${R} ${B}${C}\$ ${R}${B}" "$(basename "$1")"
  local i
  for ((i = 0; i < ${#2}; i++)); do printf "%s" "${2:i:1}"; sleep 0.012; done
  printf "%s" "$R"
  pause
  printf "\n"
  (cd "$1" && eval "$2")
}
story() {  # one line per Enter, like a slide built up live
  printf "\n"
  local line
  for line in "$@"; do printf "  ${B}%s${R}" "$line"; pause; printf "\n"; done
}
banner() {
  printf "\n\n${C}${B}"
  printf "  █████  █████   ███   █   █  █████  ████   █████   ████\n"
  printf "  █      █      █   █  ██ ██  █      █   █  █      █    \n"
  printf "  █████  ████   █████  █ █ █  █████  ████   ████   █    \n"
  printf "      █  █      █   █  █   █      █  █      █      █    \n"
  printf "  █████  █████  █   █  █   █  █████  █      █████   ████\n"
  printf "${R}\n"
  printf "  ${B}Rules your AI agent can't quietly break.${R}\n"
  printf "  ${D}Plain-English rules · real tests · approved by a person · enforced at stop, commit and CI${R}\n\n"
  pause
}
fresh_copy() {  # the project before SeamSpec, so `init` is a real first-time setup
  rm -rf "$FRESH"
  local first
  first="$(git -C "$REPO" rev-list --max-parents=0 HEAD | tail -1)"   # the project before SeamSpec
  git clone -q "$REPO" "$FRESH" && git -C "$FRESH" checkout -q "$first"
}
copy() {  # put text on the clipboard: macOS, Windows (Git Bash / WSL) or Linux
  if command -v pbcopy >/dev/null; then printf "%s" "$1" | pbcopy
  elif command -v clip.exe >/dev/null; then printf "%s" "$1" | clip.exe
  elif command -v xclip >/dev/null; then printf "%s" "$1" | xclip -selection clipboard
  else return 1; fi
}
cue() {  # a live Claude Code moment
  printf "\n${Y}${B}→ Claude Code:${R} %s\n" "$1"
  if copy "$2"; then
    printf "${D}  prompt copied to the clipboard (paste it). Press Enter here when the agent is done.${R}"
  else
    printf "  ${B}%s${R}\n${D}  (no clipboard tool: type or copy the prompt above.) Press Enter when the agent is done.${R}" "$2"
  fi
  pause
  printf "\n"
}

reset_demo() {
  cd "$REPO" || exit 1
  git checkout -q main
  git fetch -q origin main 2>/dev/null || true   # works offline too: uses the last fetched main
  git reset -q --hard origin/main          # the committed setup (moves main back if a rehearsal committed)
  git clean -q -fd                         # files a rehearsal added (ignored ones, like .venv, stay)
  rm -rf .seamspec/.local/requests .seamspec/.local/declined   # supersede requests and declines
  rm -rf .seamspec/.local/last_verify.json .seamspec/.local/catches.jsonl .seamspec/.local/reports \
    .seamspec/.local/sessions   # last result and "blocked so far" counts, so status starts clean
  git status --short
  rm -rf "$FRESH"                          # the fresh copy used to show `init`
  seamspec status | grep -E "invariants|awaiting"
  echo "Reset done. Start a NEW Claude Code session in $REPO."
}

main_flow() {
  fresh_copy >/dev/null 2>&1 || { echo "couldn't prepare the fresh copy"; exit 1; }
  clear
  banner
  printf "\n  ${B}${C}orders-demo${R}: a small online-shop backend, in Python\n"
  story \
    "Checkout takes the customer's email and card number, charges the card and records the order." \
    "Customers look up their orders; password resets use one-time tokens." \
    "Our team agreed three security rules for it:" \
    "   1. Checkout never logs the customer's email or card number." \
    "   2. A customer never sees another customer's orders." \
    "   3. A password-reset token works only once." \
    "As we built it, the agent turned each rule into a test, and I approved each one." \
    "It starts with one command, in the project:"

  say "Setting SeamSpec up (a fresh copy of the project, before SeamSpec). It asks before it ever runs a test:"
  run_in "$FRESH" "seamspec init --no-plugin --no-ci"

  say "Back in the real project: the rules in force, generated from what was approved"
  run "seamspec spec"

  cue "Prompt 1: an ordinary request (debug logging)" "$PROMPT_1"
  cue "Prompt 2: turn what it just did into a rule" "$PROMPT_2"
  cue "Who checks the agent's test? A separate, read-only reviewer (talk while it runs)" "$PROMPT_EXPLAIN"
  say "The agent proposed a rule with its own test. Only a person can approve it:"
  run "seamspec review"
  say "Three rules when we started; four now, the new one written by the agent and approved by a person:"
  run "seamspec spec"
  cue "Prompt 3: ask it to change the test instead" "$PROMPT_3"
  say "Even with the commit check skipped, CI catches a weakened test (a pretend PR):"
  run "gh pr view $PR_BRANCH --web"
  say "Done. Reset before the next run: demo.sh reset"
}

fallback_flow() {
  say "Fallback: the same guarantees without the agent. Resetting first (discards the live changes)."
  reset_demo >/dev/null
  clear

  say "1. A change that logs the whole request, email and card number included"
  run "git apply '$HERE/leak.patch' && git diff -U0 orders/service.py | grep '^[-+] '"
  run "git commit -am 'Log the request for debugging'"
  quiet "git checkout -- orders/service.py"

  say "2. Someone weakens a locked test by hand (drops the other-customer check)"
  run "perl -0pi -e 's/\\n *with pytest\\.raises\\(NotFound\\):\\n[^\\n]*//' .seamspec/tests/test_inv_95cc4200.py && git diff --stat"
  run "seamspec verify"
  quiet "git checkout -- .seamspec/tests/test_inv_95cc4200.py"

  say "3. Capture: after masking the card, the agent proposes a rule with its own test (prepared here)"
  run "git apply '$HERE/mask.patch' && git diff -U0 orders/service.py | grep '^+ '"
  local id
  id="$(cd "$REPO" && python3 - "$HERE/mask_rule_test.py" <<'EOF' | seamspec propose --json - | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
import json, sys
print(json.dumps({
    "title": "Logs show a card only as its last 4 digits",
    "assertion": "Checkout's debug log shows the card as its last 4 digits (****1234) and never the full number.",
    "scope_paths": ["orders/**"], "runner": "pytest", "harness_code": open(sys.argv[1]).read(),
    "origin_text": "Lock that: the debug log must show the card as its last 4 digits, and never more of the number.", "origin_type": "prompt",
}))
EOF
)"
  printf "${D}  proposed %s${R}\n" "$id"
  run "seamspec verify --proposed $id"
  run "seamspec review"
  say "Done. Reset before the next run: demo.sh reset"
}

case "${1:-main}" in
  main) main_flow ;;
  fallback) fallback_flow ;;
  reset) reset_demo ;;
  *) echo "usage: demo.sh [main|fallback|reset]" >&2; exit 2 ;;
esac
