# set-url
git remote set-url origin git@github.com:yangye8/100-shell-scripts.git

#clean .git
git rev-list --objects --all | grep "$(git verify-pack -v .git/objects/pack/*.idx | sort -k 3 -n | tail -5 | awk '{print$1}')"
git filter-branch -f --prune-empty --index-filter 'git rm -rf --cached --ignore-unmatch <file>' --tag-name-filter cat -- --all
git filter-branch -f --prune-empty --index-filter 'git rm -rf --cached --ignore-unmatch <file>' --tag-name-filter cat -- --all
git push origin --force --all

#submodule
git submodule add <url> <path>
git commit -am "xxx"
git push
# update submodule
git submodule foreach git checkout master
git submodule foreach git pull
#submodule clone
git clone <repository> --recursive
