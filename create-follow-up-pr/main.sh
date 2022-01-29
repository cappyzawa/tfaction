#!/usr/bin/env bash

set -eu
set -o pipefail

# create a pull request with empty commit
# 1. create a remote branch
# 2. create a label
# 3. open pull request

follow_up_branch="follow-up-$CI_INFO_PR_NUMBER-$TFACTION_TARGET-$(date +%Y%m%dT%H%M%S)"
GITHUB_TOKEN="$GITHUB_APP_TOKEN" ghcp empty-commit \
	-r "$GITHUB_REPOSITORY" -b "$follow_up_branch" \
	-m "chore: empty commit to open follow up pull request

Follow up #$CI_INFO_PR_NUMBER
https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

git pull origin "$follow_up_branch"
git fetch origin "$follow_up_branch"
git branch "$follow_up_branch" "origin/$follow_up_branch"

pr_title="chore($TFACTION_TARGET): follow up #$CI_INFO_PR_NUMBER"
pr_body="This pull request was created automatically to follow up the failure of apply.

Follow up #$CI_INFO_PR_NUMBER ([failed workflow](https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID))

1. Check the error message #$CI_INFO_PR_NUMBER
1. Check the result of \`terraform plan\`
1. Add commits to this pull request and fix the problem if needed
1. Review and merge this pull request"

label=${TFACTION_TARGET_LABEL_PREFIX}${TFACTION_TARGET}

curl \
	-X POST \
	-H "Authorization: token $GITHUB_TOKEN" \
	-H "Accept: application/vnd.github.v3+json" \
	"https://api.github.com/repos/$GITHUB_REPOSITORY/labels" \
	-d "{\"name\":\"$label\"}"

create_opts=(-H "$follow_up_branch" -t "$pr_title" -b "$pr_body" -l "$label")
if ! [[ "$CI_INFO_PR_AUTHOR" =~ \[bot\] ]]; then
	create_opts+=( -a "$CI_INFO_PR_AUTHOR" )
fi
if ! [[ "$GITHUB_ACTOR" =~ \[bot\] ]]; then
	create_opts+=( -a "$GITHUB_ACTOR" )
fi
if [ "$TFACTION_DRAFT_PR" = "true" ]; then
	create_opts+=( -d )
fi

follow_up_pr_url=$(env GITHUB_TOKEN="$GITHUB_APP_TOKEN" gh pr create "${create_opts[@]}")

github-comment post -config "${GITHUB_ACTION_PATH}/github-comment.yaml" -var "follow_up_pr_url:$follow_up_pr_url" -k create-follow-up-pr