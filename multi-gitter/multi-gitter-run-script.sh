#!/usr/bin/env bash

echo -e "\n***************************************************\n* ${REPOSITORY}\n***************************************************\n"

set -x

rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/my-defaults/" .

case "${REPOSITORY}" in
  ## action
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/action-my-broken-link-checker
  # ruzickap/action-my-markdown-link-checker
  # ruzickap/action-my-markdown-linter
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/action-*)
    echo -e "\n*** action | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/action/" .
    ;;&

  ## ansible
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/ansible-my_workstation
  # ruzickap/ansible-openwrt
  # ruzickap/ansible-raspbian
  # ruzickap/packer-templates
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/packer-templates | ruzickap/ansible-*)
    echo -e "\n*** ansible | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/ansible/" .
    ;;&
  ruzickap/packer-templates)
    echo -e "\n*** ansible-ch | ${REPOSITORY}\n"
    git checkout .gitignore
    ;;

  ## latex
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/cheatsheet-macos
  # ruzickap/cv
  # ruzickap/cheatsheet-systemd
  # ruzickap/cheatsheet-atom
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/cheatsheet-* | ruzickap/cv)
    echo -e "\n*** latex | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/latex/" .
    ;;&
  ruzickap/cv)
    echo -e "\n*** latex-ch | ${REPOSITORY}\n"
    git checkout run.sh
    ;;

  ## hugo
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/petr.ruzicka.dev
  # ruzickap/xvx.cz
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
    echo -e "\n*** hugo | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/hugo/" .
    ;;&

  ## vuepress
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/k8s-eks-bottlerocket-fargate
  # ruzickap/k8s-fargate-eks
  # ruzickap/k8s-flux-istio-gitlab-harbor
  # ruzickap/k8s-harbor
  # ruzickap/k8s-istio-webinar
  # ruzickap/k8s-jenkins-x
  # ruzickap/k8s-knative-gitlab-harbor
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/k8s-eks-bottlerocket-fargate | ruzickap/k8s-fargate-eks | ruzickap/k8s-flux-istio-gitlab-harbor | ruzickap/k8s-harbor | ruzickap/k8s-istio-webinar | ruzickap/k8s-jenkins-x | ruzickap/k8s-knative-gitlab-harbor)
    echo -e "\n*** vuepress | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/vuepress/" .
    ;;&
  ruzickap/k8s-fargate-eks)
    echo -e "\n*** vuepress-ch | ${REPOSITORY}\n"
    rm -v .mlc_config.json .lycheeignore
    ;;
  ruzickap/k8s-flux-istio-gitlab-harbor | ruzickap/k8s-knative-gitlab-harbor)
    echo -e "\n*** vuepress-ch | ${REPOSITORY}\n"
    git checkout .github/workflows/vuepress-build.yml .mlc_config.json .lycheeignore
    ;;
  ruzickap/k8s-jenkins-x)
    echo -e "\n*** vuepress-ch | ${REPOSITORY}\n"
    git checkout .github/workflows/vuepress-build.yml .lycheeignore .mlc_config.json .trivyignore.yaml .checkov.yml
    ;;

  ## vuepress-terraform
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/k8s-flagger-istio-flux
  # ruzickap/k8s-istio-workshop
  # ruzickap/k8s-postgresql
  # ruzickap/k8s-sockshop
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/k8s-sockshop | ruzickap/k8s-postgresql | ruzickap/k8s-istio-workshop | ruzickap/k8s-flagger-istio-flux)
    echo -e "\n*** vuepress-terraform | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/vuepress-terraform/" .
    ;;&
  ruzickap/k8s-postgresql)
    echo -e "\n*** vuepress-terraform-ch | ${REPOSITORY}\n"
    git checkout .checkov.yml
    ;;

  ## ansible-role
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/ansible-role-my_common_defaults
  # ruzickap/ansible-role-proxy_settings
  # ruzickap/ansible-role-virtio-win
  # ruzickap/ansible-role-vmwaretools
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/ansible-role-my_common_defaults | ruzickap/ansible-role-proxy_settings | ruzickap/ansible-role-virtio-win | ruzickap/ansible-role-vmwaretools)
    echo -e "\n*** ansible-role | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/ansible-role/" .
    ;;&
  ruzickap/ansible-role-my_common_defaults)
    echo -e "\n*** ansible-role-ch | ${REPOSITORY}\n"
    rm .github/workflows/release-ansible-galaxy.yml
    git checkout .github/workflows/molecule.yml
    ;;
  ruzickap/ansible-role-vmwaretools)
    echo -e "\n*** ansible-role-ch | ${REPOSITORY}\n"
    git checkout .checkov.yml
    rm ansible/.ansible-lint
    ;;

  ## default
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/blog-test.ruzicka.dev
  # ruzickap/container-build
  # ruzickap/darktable_video_tutorials_list
  # ruzickap/gha-test
  # ruzickap/k8s-eks-flux - is using VuePress 2 - needs different defaults then old VuePress 1.x
  # ruzickap/k8s-eks-rancher
  # ruzickap/k8s-harbor-presentation
  # ruzickap/k8s-istio-demo
  # ruzickap/k8s-tf-eks-gitops
  # ruzickap/malware-cryptominer-container
  # ruzickap/my-git-projects
  # ruzickap/myteam-adr
  # ruzickap/packer-virt-sysprep
  # ruzickap/popular-containers-vulnerability-checks
  # ruzickap/raw-photo-tools-container
  # ruzickap/ruzickap
  # ruzickap/test_usb_stick_for_tv
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/blog-test.ruzicka.dev)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .markdownlint.yml .mega-linter.yml
    ;;
  ruzickap/container-build)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    rm .github/workflows/release-please.yml
    git checkout .github/renovate.json5
    ;;
  ruzickap/k8s-harbor-presentation)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/renovate.json5
    ;;
  ruzickap/k8s-istio-demo)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/workflows/links.yml
    ;;
  ruzickap/k8s-tf-eks-gitops)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .checkov.yml .markdownlint.yml .github/renovate.json5 .mega-linter.yml
    ;;
  ruzickap/malware-cryptominer-container | ruzickap/raw-photo-tools-container)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    rm .github/workflows/release-please.yml
    ;;
  ruzickap/my-git-projects)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/renovate.json5
    ;;
  ruzickap/ruzickap.github.io)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/renovate.json5 lychee.toml .markdownlint.yml
    ;;
  ruzickap/myteam-adr)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .markdownlint.yml
    ;;
esac
