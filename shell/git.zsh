# ┌─────────────────────────────────────────────────────────────────┐
# │ Git Aliases — Comprehensive Oh-My-Zsh git plugin aliases        │
# └─────────────────────────────────────────────────────────────────┘

alias g="git"
alias gst="git status"
alias gs="git status --short"
alias gss="git status --short"
alias gsb="git status --short --branch"

alias ga="git add"
alias gaa="git add ."
alias gapa="git add --patch"
alias gau="git add --update"
alias gav="git add --verbose"

alias gb="git branch"
alias gba="git branch --all"
alias gbd="git branch --delete"
alias gbD="git branch --delete --force"
alias gbm="git branch --move"
alias gbr="git branch --remote"
alias gbnm="git branch --no-merged"

alias gc="git commit --verbose"
alias gcm="git commit -m"
alias gcmsg="git commit --message"
alias gca="git commit --verbose --all"
alias gcam="git commit --all --message"
alias gcn="git commit --verbose --no-edit"
alias gcs="git commit --gpg-sign"
alias gcsm="git commit --signoff --message"

alias gco="git checkout"
alias gcor="git checkout --recurse-submodules"
alias gcb="git checkout -b"
alias gsw="git switch"
alias gswc="git switch --create"

alias gcl="git clone --recurse-submodules"
alias gclean="git clean --interactive -d"

alias gd="git diff"
alias gds="git diff --staged"
alias gdca="git diff --cached"
alias gdw="git diff --word-diff"

alias gf="git fetch"
alias gfa="git fetch --all --tags --prune --jobs=10"
alias gfo="git fetch origin"

alias gl="git log --oneline --graph"
alias glg="git log --stat"
alias glgg="git log --graph"
alias glgga="git log --graph --decorate --all"
alias glgm="git log --graph --max-count=10"
alias glo="git log --oneline --decorate"
alias glog="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gloga="git log --oneline --decorate --graph --all"

alias gm="git merge"
alias gma="git merge --abort"
alias gmc="git merge --continue"
alias gms="git merge --squash"

alias gp="git push"
alias gpd="git push --dry-run"
alias gpf="git push --force-with-lease --force-if-includes"
alias gph="git push -u origin HEAD"
alias gpo="git push origin"
alias gpu="git push upstream"
alias gpv="git push --verbose"
alias gpsup="git push --set-upstream origin \$(git_current_branch)"

alias gpl="git pull"
alias gpr="git pull --rebase"
alias gpra="git pull --rebase --autostash"

alias gr="git rebase"
alias grb="git rebase"
alias grba="git rebase --abort"
alias grbc="git rebase --continue"
alias grbi="git rebase --interactive"
alias grbs="git rebase --skip"

alias grh="git reset --hard"
alias grhh="git reset --hard"
alias grs="git reset --soft HEAD~1"
alias grhk="git reset --keep"

alias grm="git rm"
alias grmc="git rm --cached"

alias gsta="git stash push"
alias gstaa="git stash apply"
alias gstl="git stash list"
alias gstp="git stash pop"
alias gstd="git stash drop"
alias gstc="git stash clear"
alias gsts="git stash show --patch"

alias gcf="git config --list"
alias gcount="git shortlog --summary --numbered"
alias gsh="git show"
alias gignore="git update-index --assume-unchanged"
alias gunignore="git update-index --no-assume-unchanged"
alias gbl="git blame -w"
alias grv="git remote --verbose"
alias gra="git remote add"
alias grrm="git remote remove"

alias gcp="git cherry-pick"
alias gcpa="git cherry-pick --abort"
alias gcpc="git cherry-pick --continue"

alias grev="git revert"
alias gsi="git submodule init"
alias gsu="git submodule update"
alias gta="git tag --annotate"
alias gts="git tag --sign"

alias gwt="git worktree"
alias gwta="git worktree add"
alias gwtls="git worktree list"
alias gwtmv="git worktree move"
alias gwtrm="git worktree remove"

alias grt='cd "\$(git rev-parse --show-toplevel || echo .)"'
alias gbclean='git branch --merged | grep -v "\\*\|main\|master\|develop" | xargs -n 1 git branch -d'
