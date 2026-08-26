# wt — jump between git worktrees with an fzf picker.
#
#   wt              open the picker
#   wt <pattern>    prefilter; jumps straight there on a single match
#
# Requires: zsh, git, fzf (>= 0.38). MIT licensed.

typeset -g WT_VERSION="0.1.0"

# Editor opened by ctrl-o. Falls back to $EDITOR, then to VS Code.
: ${WT_EDITOR:=${EDITOR:-code}}
# fzf layout knobs, override before sourcing or at any time.
: ${WT_HEIGHT:="~80%"}
: ${WT_PREVIEW_WINDOW:="right,58%,border-left,~1"}
# Commits shown in the preview pane.
: ${WT_PREVIEW_LOG:=10}

# Clipboard command used by ctrl-y, detected per platform.
_wt_copy_cmd() {
  if [[ -n $WT_COPY_CMD ]]; then
    print -r -- "$WT_COPY_CMD"
  elif (( $+commands[pbcopy] )); then
    print -r -- "pbcopy"
  elif (( $+commands[wl-copy] )); then
    print -r -- "wl-copy"
  elif (( $+commands[xclip] )); then
    print -r -- "xclip -selection clipboard"
  else
    print -r -- "cat >/dev/null"
  fi
}

# One row per worktree: "<commit ts>\t<display>\t<path>", newest commit first.
# Emitted as a string so fzf can re-run it for ctrl-r.
_wt_rows_cmd() {
  print -r -- 'git worktree list --porcelain | awk "/^worktree /{print \$2}" | while IFS= read -r w; do
    b=$(git -C "$w" branch --show-current 2>/dev/null); [ -n "$b" ] || b="(detached)"
    n=$(git -C "$w" status --porcelain 2>/dev/null | grep -c .)
    if [ "$n" -gt 0 ]; then d="±$n"; c="\033[33m"; else d="clean"; c="\033[2;32m"; fi
    [ "$w" = "$PWD" ] && m="●" || m=" "
    printf "%s\t\033[35m%s\033[0m \033[1;36m%-40s\033[0m %b%-6s\033[0m \033[2m%-13s %s\033[0m\t%s\n" \
      "$(git -C "$w" log -1 --format=%ct 2>/dev/null)" "$m" "$b" "$c" "$d" \
      "$(git -C "$w" log -1 --format=%cr 2>/dev/null)" "$(printf %s "$w" | sed "s|^$HOME|~|")" "$w"
  done | sort -rn | cut -f2-'
}

_wt_usage() {
  print -r -- "wt $WT_VERSION — jump between git worktrees

usage:
  wt [pattern]        open the picker, prefiltered by pattern
  wt -h | --help      this message
  wt -l | --list      print worktrees as plain text
  wt --version        print version

keys:
  enter    cd to the worktree
  ctrl-o   open it in \$WT_EDITOR ($WT_EDITOR)
  ctrl-y   copy its path to the clipboard
  ctrl-r   refresh dirty counts
  ?        toggle the preview pane

env:
  WT_EDITOR, WT_COPY_CMD, WT_HEIGHT, WT_PREVIEW_WINDOW, WT_PREVIEW_LOG"
}

wt() {
  case $1 in
    -h|--help) _wt_usage; return 0 ;;
    --version) print -r -- "wt $WT_VERSION"; return 0 ;;
    -l|--list) eval "$(_wt_rows_cmd)"; return 0 ;;
  esac

  (( $+commands[git] )) || { print -u2 "wt: git not found"; return 1 }
  (( $+commands[fzf] )) || { print -u2 "wt: fzf not found — install it from https://github.com/junegunn/fzf"; return 1 }
  git rev-parse --git-common-dir >/dev/null 2>&1 || { print -u2 "wt: not a git repository"; return 1 }

  local rows="$(_wt_rows_cmd)"
  local label="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")"
  local preview="git -C {-1} -c color.ui=always log --graph --format=\"%C(auto)%h %C(dim)%cr%C(reset) %s\" -$WT_PREVIEW_LOG
    echo
    git -C {-1} -c color.status=always status -sb | head -20"

  local sel
  sel=$(eval "$rows" | fzf \
    --ansi --delimiter=$'\t' --with-nth=1 \
    --height=$WT_HEIGHT --min-height=14 --layout=reverse --border=rounded --info=inline-right \
    --prompt='worktree ▸ ' --pointer='▸' --no-multi --cycle --select-1 --exit-0 \
    --border-label=" ${label:-worktrees} " \
    --header=$'enter cd · ctrl-o editor · ctrl-y copy · ctrl-r refresh · ? preview' \
    --color='label:cyan,header:italic:dim,border:dim,prompt:cyan,pointer:magenta,hl:yellow,hl+:yellow' \
    --preview="$preview" --preview-window="$WT_PREVIEW_WINDOW" \
    --bind='?:toggle-preview' \
    --bind="ctrl-r:reload($rows)" \
    --bind="ctrl-o:execute-silent($WT_EDITOR {-1})+abort" \
    --bind="ctrl-y:execute-silent(printf %s {-1} | $(_wt_copy_cmd))" \
    ${1:+--query=$1}) || return
  [[ -n $sel ]] || return
  cd "${sel##*$'\t'}"
}

# Completion over branch names of the current repository's worktrees.
_wt_complete() {
  local -a branches
  branches=( ${(f)"$(git worktree list --porcelain 2>/dev/null | awk '/^branch /{sub(/^refs\/heads\//, "", $2); print $2}')"} )
  compadd -a branches
}
if (( $+functions[compdef] )); then
  compdef _wt_complete wt
fi
