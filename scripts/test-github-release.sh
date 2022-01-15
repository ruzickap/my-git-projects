#!/usr/bin/env bash

set -euxo pipefail

TMP_DIR="/tmp/test-repo"

terraform -chdir=../terraform init
terraform -chdir=../terraform apply -auto-approve
git clone git@github.com:ruzickap/test-repo.git "${TMP_DIR}"

GITHUB_LABELS=("bug" "enhancement" "documentation")

cd "${TMP_DIR}"

mkdir -pv .github/workflows
ln -s /Users/ruzickap/git/my-git-projects/.release-it.yml .release-it.yml

for COUNTER in {1..20} ; do
  echo "${COUNTER}: $(date)" >> my-date
  git checkout -b "branch${COUNTER}"
  git add my-date
  git commit -a -m "Test commit ${COUNTER}"
  git push
  RANDOM=$$$(date +%s)
  GITHUB_PR_URL=$(gh pr create --fill --label "${GITHUB_LABELS[$RANDOM % ${#GITHUB_LABELS[@]}]}" | grep '^https://github.com/')
  gh pr merge --rebase "${GITHUB_PR_URL}"
  git checkout main
  git pull -r
  git branch -D "branch${COUNTER}"
  if [[ $(( COUNTER % 5 )) -eq 0 ]] ; then
    release-it --only-version
  fi
done

cat << EOF
----------------------------------------------------------------
rm -rf "${TMP_DIR}" && terraform -chdir=../terraform destroy -auto-approve
EOF
