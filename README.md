# GitHub

This README is a personal collection of useful Git and GitHub commands and workflows.

## Table of Contents

- [General Links and Info](#general-links-and-info)
- [Basic Git Workflow & Contributing](#basic-git-workflow--contributing)
  - [Contribution](#contribution)
  - [Local development](#local-development)
- [Managing Branches](#managing-branches)
  - [Merge changes from main to my local branch](#merge-changes-from-main-to-my-local-branch)
- [Amending Commits & Tags](#amending-commits--tags)
  - [Squash 2 last commits](#squash-2-last-commits)
  - [Amend older commit message](#amend-older-commit-message)
  - [Rename tag](#rename-tag)
  - [Delete tag](#delete-tag)
- [Working with Submodules](#working-with-submodules)
  - [Update git submodules](#update-git-submodules)
- [GitHub Actions & Releases](#github-actions--releases)
  - [Update GitHub Action with tag @1](#update-github-action-with-tag-1)
  - [Sample commit for a Pull Request](#sample-commit-for-a-pull-request)
  - [List all GitHub actions in my repos](#list-all-github-actions-in-my-repos)

## General Links and Info

My projects on GitHub: [https://ruzickap.github.io](https://ruzickap.github.io)

<https://profile-summary-for-github.com/user/ruzickap>

GitHub's official command-line tool (`gh`): [https://cli.github.com/](https://cli.github.com/)

## Basic Git Workflow & Contributing

### Contribution

This section outlines the process for contributing to an external GitHub repository.

```bash
GITHUB_REPO_TO_CONTRIBUTE="https://github.com/oxsecurity/megalinter"
BRANCH_NAME="improve-tflint-docs"

# Fork the target repository to your account, clone it locally,
# and set up the original repository as the 'upstream' remote.
gh repo fork --clone --remote ${GITHUB_REPO_TO_CONTRIBUTE}
cd "$(basename "${GITHUB_REPO_TO_CONTRIBUTE}")"

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

This section describes a typical workflow for local development on your own
repositories.

```bash
# clone GitHub repository
git clone git@github.com:ruzickap/packer-templates.git
cd packer-templates

# create new branch
git checkout -b "my_new_branch"

# do the changes
git add my_changed_file && git commit -m "done with feature"

# open a pull request for the topic branch you've just pushed
gh pr create --web --fill

# After the PR is reviewed and approved, it's typically Squash and Merged
# via the GitHub UI.

# once PR is merged then remove the branch
git checkout main
git pull -r
git branch -D my_new_branch
```

## Managing Branches

### Merge changes from main to my local branch

This section describes two ways to update your local feature branch with the
latest changes from the `main` branch using `git rebase`. Rebasing helps
maintain a cleaner commit history.

Check: [https://codewithhugo.com/fix-git-failed-to-push-updates-were-rejected/](https://codewithhugo.com/fix-git-failed-to-push-updates-were-rejected/)

The first method fetches all remote changes, then rebases your current branch
onto `main`. If conflicts occur, `git mergetool` can be used to resolve them,
followed by `git rebase --continue`.

```bash
git fetch
git rebase main
git mergetool
git rebase --continue
```

The second method is more explicit, ensuring `main` is up-to-date first,
then checking out the feature branch and rebasing it. It also includes steps
for resolving conflicts manually if they occur during the rebase.

```bash
git checkout main
git pull -r && git submodule update --init
git checkout feature/improve_documentation
git rebase main
git status
# vim docs/test.rst
# do the changes
git add docs/test.rst
git rebase --continue
git push -f ruzickap feature/improve_documentation
```

## Amending Commits & Tags

### Squash 2 last commits

This command sequence is used to combine the last two commits into a single
commit. `HEAD~2` refers to the last two commits from the current HEAD.
The `-i` flag starts an interactive rebase session.

```bash
git add some_file
git commit -m 'Squash this' && git rebase -i HEAD~2 && git push -f
# for the commit(s) you want to merge into the preceding one.
# Then save and close the editor. `git push -f` is needed as history is rewritten.
```

### Amend older commit message

[https://help.github.com/en/github/committing-changes-to-your-project/changing-a-commit-message#amending-older-or-multiple-commit-messages](https://help.github.com/en/github/committing-changes-to-your-project/changing-a-commit-message#amending-older-or-multiple-commit-messages)

To change the message of an older commit:

1. Use `git log` to find the hash of the commit *before* the one you want
   to amend.
2. Start an interactive rebase. The `^` on the commit hash means you're
   starting the rebase from the parent of that commit, allowing you to edit
   the commit itself. Change 'pick' to 'reword' (or 'r') for the commit
   you want to change, then save and exit.
You'll be prompted to enter the new commit message.
Since this rewrites history, a force push (`git push --force`) is required.

```bash
git log
# Example: If you want to amend commit d0efb71, and its parent is 123abcd
# you would use 123abcd or 'd0efb71^'
git rebase -i 'd0efb71^' # Or use the hash of the commit *before* d0efb71

# In the interactive rebase screen:
# Change 'pick' to 'reword' for commit d0efb71
#   reword d0efb71 test commit
# Save and close the editor.
# Then, Git will open another editor for you to change the commit message.
#   my new commit
# Save and close again.

# After amending the message in the editor and saving,
# you may need to force push the changes.
git push --force
```

### Rename tag

To rename a Git tag (e.g., from "old" to "new"):

1. Create a new annotated tag "new" pointing to the same commit as "old".
   `old^{}` dereferences the old tag to the commit it points to, ensuring
   the new tag points to the commit itself, not the old tag object.
2. Delete the old local tag "old".
3. Delete the old remote tag "old".
4. Push the new tag "new" to the remote.

```bash
git tag -a new old^{}
git tag -d old
git push origin :refs/tags/old
git push --tags
```

### Delete tag

```bash
git push origin :refs/tags/my-tag-name
git tag -d my-tag-name
```

## Working with Submodules

### Update git submodules

This command initializes any uninitialized submodules and updates existing
ones to the commit specified in the parent repository. The `--recursive`
flag ensures that any nested submodules are also initialized and updated.

```bash
git submodule update --init --recursive
```

## GitHub Actions & Releases

### Update GitHub Action with tag @1

This section deals with managing tags, often for versioning GitHub Actions
or releases.

To list existing tags formatted with their subject (often the release title
or version) in a table:

```bash
git for-each-ref --format="%(refname:short) | %(subject)" refs/tags | column -t
```

Output example:

```console
v1      |  Release  v1.0.0
v1.0.0  |  Release  1.0.0
```

Delete `v1` tag (if, for example, `v1` was a moving tag and you want to
replace it with a specific version like `v1.0.0`):

```bash
git push --delete origin v1
git tag -d v1
```

Create release:

For manual tagging and pushing:

```bash
git tag v3.0.6
git push --tags
```

### Sample commit for a Pull Request

This shows an example workflow for creating a feature branch, making commits,
and opening a pull request. The commit message
`feat(gh_actions): replace stale + add commitlint` follows the Conventional
Commits specification, which can be useful for automated changelog generation
and semantic versioning.

```bash
git status
git add .github/workflows/commitlint.yml .github/workflows/stale.yml
git checkout -b stale
git commit -m "feat(gh_actions): replace stale + add commitlint"
git push
gh pr create --web --fill

# After PR merge and cleanup:
git checkout main
git branch -D stale
git pull -r
```

### List all GitHub actions in my repos

This command searches for all GitHub Actions workflow files (`*.yml`) within
a specified directory structure (`~/git/` up to 4 levels deep). It then uses
`awk` to extract the `uses:` lines (which specify the action being used,
e.g., `actions/checkout@v2`) from these files, sorts them, and shows unique
entries. This is useful for getting an overview of common actions used across
your repositories.

```bash
find ~/git/ -maxdepth 4 -path "*/.github/workflows/*.yml" -type f -exec awk -F' uses: ' '/^\s*uses: \w/ || /^\s*- uses: \w/ { print "      - uses: " $2 }' {} \; | sort | uniq
```
