#!/bin/bash
if [ "$1" == "--help" ] || [ "$1" == "-h" ] || [ "$1" == "" ]; then
    echo "getrepo: "
    echo "Usage : List public repositories and total commits for a given GitHub user"
    echo "syntax : getrepo <username>"
    echo "Example: getrepo Sudharshan1409"
    exit 0
fi

username=$1
api_url="https://api.github.com/users/$username/repos"
repo_response=$(curl -s $api_url)
repo_names=$(echo "$repo_response" | jq -r '.[].name')

echo "Repositories for $username:"
for repo_name in $repo_names; do
    commits_api_url="https://api.github.com/repos/$username/$repo_name/commits"
    commits_response=$(curl -s $commits_api_url)
    total_commits=$(echo "$commits_response" | jq '. | length')
    echo "$repo_name - Total commits: $total_commits"
done
