# wt

Jump between git worktrees from a small fzf picker.

```
┌ acme ─────────────────────────────────────────────────────────────────┐
worktree ▸ bill
  feat/billing-webhooks                    clean  4 hours ago   ~/code/.worktrees/acme-billing
▸ ● fix/checkout-total-rounding            ±2     7 hours ago   ~/code/acme
```

Each row shows the branch, how many files are dirty, when the last commit
landed, and the path. Rows are sorted by last commit, and `●` marks the
worktree you are standing in. The preview pane shows the commit graph and
`git status -sb` for the highlighted worktree.

## Install

Requires zsh, git, and [fzf](https://github.com/junegunn/fzf) 0.38 or newer.

Manual:

```sh
git clone https://github.com/pierresavary562935/zsh-wt.git ~/.zsh-wt
echo 'source ~/.zsh-wt/wt.plugin.zsh' >> ~/.zshrc
```

Or run `./install.sh` from the clone, which appends that line for you.

Oh My Zsh:

```sh
git clone https://github.com/pierresavary562935/zsh-wt.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/wt
# then add wt to plugins=(...) in ~/.zshrc
```

zinit: `zinit light pierresavary562935/zsh-wt` — antidote/antigen: `antidote bundle pierresavary562935/zsh-wt`.

## Use

```sh
wt              # open the picker
wt billing      # prefilter; cd straight there when only one worktree matches
wt --list       # plain text listing, no picker
wt --help
```

| key | action |
| --- | --- |
| `enter` | cd to the worktree |
| `ctrl-o` | open it in `$WT_EDITOR` |
| `ctrl-y` | copy its path to the clipboard |
| `ctrl-r` | refresh the dirty counts |
| `?` | toggle the preview pane |
| `esc` | cancel |

Tab completion offers the branch names of the current repository's worktrees.

## Configure

Set any of these before sourcing the plugin, or at any time afterwards.

| variable | default | meaning |
| --- | --- | --- |
| `WT_EDITOR` | `$EDITOR`, else `code` | editor launched by `ctrl-o` |
| `WT_COPY_CMD` | `pbcopy`, `wl-copy`, or `xclip` | clipboard command for `ctrl-y` |
| `WT_HEIGHT` | `~80%` | fzf height |
| `WT_PREVIEW_WINDOW` | `right,58%,border-left,~1` | fzf preview window spec |
| `WT_PREVIEW_LOG` | `10` | commits shown in the preview |

## Notes

`wt` has to be a shell function rather than a script on `$PATH`, because a
child process cannot change the directory of your shell.

It lists whatever `git worktree list` reports, so worktrees scattered across
different parent directories all show up in one place.

## License

MIT
