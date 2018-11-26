git fetch --all --prune;

for branch in $(git branch -r --merged master | grep origin | grep -v develop | grep -v master | sed -E "s|^ *origin/||g")
do
    git push origin $branch --delete
done;

git fetch --all --prune;