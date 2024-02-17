# GitHub

My projects on GitHub: [https://ruzickap.github.io](https://ruzickap.github.io)

<https://profile-summary-for-github.com/user/ruzickap>

## Git / GitHub notes

GitHub's official command-line tool (`gh`): [https://cli.github.com/](https://cli.github.com/)

### Contribution

```bash
GITHUB_REPO_TO_CONTRIBUTE="https://github.com/oxsecurity/megalinter"
BRANCH_NAME="improve-tflint-docs"

# fork and clone GitHub repository
gh repo fork --clone --remote ${GITHUB_REPO_TO_CONTRIBUTE}
cd "$(basename \"${GITHUB_REPO_TO_CONTRIBUTE}\")" || exit

# create new branch
git checkout -b "${BRANCH_NAME}"

# Do the changes
git add my_changed_file && git commit -m "done with feature"

# push the changes to your new remote (https://github.com/cli/cli/issues/546)
git push origin "${BRANCH_NAME}"

# open a pull request for the topic branch you've just pushed
gh pr create --web --fill

# once PR is merged then remove the branch
git checkout main
git pull -r
git branch -D "${BRANCH_NAME}"
```

### Local development

```bash
# clone GitHub repository
git clone git@github.com:ruzickap/packer-templates.git
cd packer-templates || exit

# create new branch
git checkout -b "my_new_branch"

# do the changes
git add my_changed_file && git commit -m "done with feature"

# open a pull request for the topic branch you've just pushed
gh pr create --web --fill

# Squash and Merge

# once PR is merged then remove the branch
git checkout main
git pull -r
git branch -D my_new_branch
```

### Merge changes from main to my local branch

Check: [https://codewithhugo.com/fix-git-failed-to-push-updates-were-rejected/](https://codewithhugo.com/fix-git-failed-to-push-updates-were-rejected/))

```bash
git fetch
git rebase main
git mergetool
git rebase --continue
```

or ...

```bash
git checkout main
git pull -r && git submodule update --init
git checkout feature/improve_documentation
git rebase main
git status
vim docs/test.rst
# do the changes
git add docs/test.rst
git rebase --continue
git push -f ruzickap feature/improve_documentation
```

### Squash 2 last commits

```bash
git add some_file
git commit -m 'Squash this' && git rebase -i HEAD~2 && git push -f
# in your editor put "f" in front of the commit you want to squash
```

### Update git submodules

```bash
git submodule update --init --recursive
```

### Update GitHub Action with tag @1

Check tags:

```bash
git for-each-ref --format="%(refname:short) | %(subject)" refs/tags | column -t
```

Output:

```console
v1      |  Release  v1.0.0
v1.0.0  |  Release  1.0.0
```

Delete `v1` tag:

```bash
git push --delete origin v1
git tag -d v1
```

Create release:

```bash
release-it
```

or

```bash
git tag v3.0.6
git push --tags
```

### Delete tag

```bash
git push origin :refs/tags/my-tag-name
git tag -d my-tag-name
```

### Amend older commit message

[https://help.github.com/en/github/committing-changes-to-your-project/changing-a-commit-message#amending-older-or-multiple-commit-messages](https://help.github.com/en/github/committing-changes-to-your-project/changing-a-commit-message#amending-older-or-multiple-commit-messages)

```bash
git log
git rebase -i 'd0efb718512fe78475056c5370884ca53f5df82b^'

reword d0efb71 test commit

my new commit

git push --force
```

### Rename tag

```bash
git tag -a new old^{}
git tag -d old
git push origin :refs/tags/old
git push --tags
```

### Sample commit

```bash
git status
git add .github/workflows/commitlint.yml .github/workflows/stale.yml
git checkout -b stale
git commit -m "feat(gh_actions): replace stale + add commitlint"
git push
gh pr create --web --fill

git checkout main
git branch -D stale
git pull -r
```

### List all GitHub actions in my repos

```bash
find ~/git/ -maxdepth 4 -path "*/.github/workflows/*.yml" -type f -exec awk -F' uses: ' '/^\s*uses: \w/ || /^\s*- uses: \w/ { print "      - uses: " $2 }' {} \; | sort | uniq
```
