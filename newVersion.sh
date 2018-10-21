#!/bin/bash

versions=$(npm view @vue/cli versions --json)

versions=${versions//\"/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

blocklist=(3.0.0-alpha.1 3.0.0-alpha.2 3.0.0-alpha.3 3.0.0-alpha.4 3.0.0-alpha.5 3.0.0-alpha.6 3.0.0-alpha.7
3.0.0-alpha.8 3.0.0-alpha.9 3.0.0-alpha.10 3.0.0-alpha.11 3.0.0-alpha.12 3.0.0-alpha.13
3.0.0-beta.1 3.0.0-beta.2 3.0.0-beta.3 3.0.0-beta.4 3.0.0-beta.5 3.0.0-beta.6 3.0.0-beta.7 3.0.0-beta.8
3.0.0-beta.9 3.0.0-beta.10 3.0.0-beta.11 3.0.0-beta.12 3.0.0-beta.13 3.0.0-beta.14 3.0.0-beta.15 3.0.0-beta.16
3.0.0-rc.1 3.0.0-rc.2 3.0.0-rc.3 3.0.0-rc.4 3.0.0-rc.5 3.0.0-rc.6
3.0.0-rc.7 3.0.0-rc.8 3.0.0-rc.9 3.0.0-rc.10 3.0.0-rc.11 3.0.0-rc.12
3.0.0 3.0.1 3.0.2 3.0.3 3.0.4 3.0.5
3.1.0 3.1.1 3.1.2 3.1.3
3.2.0 3.2.1 3.2.2 3.2.3
3.3.0
3.4.0 3.4.1
3.5.0 3.5.1 3.5.2 3.5.3 3.5.4 3.5.5
3.6.0 3.6.1 3.6.2 3.6.3
3.7.0
3.8.0 3.8.2 3.8.3 3.8.4
3.9.0 3.9.1 3.9.2 3.9.3
3.10.0
3.11.0
3.12.0 3.12.1
4.0.0-alpha.0 4.0.0-alpha.1 4.0.0-alpha.2 4.0.0-alpha.3 4.0.0-alpha.4 4.0.0-alpha.5
4.0.0-beta.0 4.0.0-beta.1 4.0.0-beta.2 4.0.0-beta.3
4.0.0-rc.0 4.0.0-rc.1 4.0.0-rc.2 4.0.0-rc.3 4.0.0-rc.4 4.0.0-rc.5
4.0.0-rc.6 4.0.0-rc.7 4.0.0-rc.8
4.0.0 4.0.1 4.0.2 4.0.3 4.0.4 4.0.5
4.1.0-beta.0
5.0.0-alpha.5 5.0.0-alpha.6 5.0.0-alpha.7)

lastVersion="4.1.0"
rebaseNeeded=false

for version in "${versions[@]}"
do

  if [[ " ${blocklist[@]} " =~ " ${version} " ]]
  then
    echo "Skipping blocklisted ${version}"
    continue
  fi

  if [ `git branch --list ${version}` ] || [ `git branch --list --remote origin/${version}` ]
  then
    echo "${version} already generated."
    git checkout ${version}
    if [ ${rebaseNeeded} = true ]
    then
      git rebase --onto ${lastVersion} HEAD~ ${version} -X theirs --keep-empty
      diffStat=`git --no-pager diff HEAD~ --shortstat`
      # git push origin ${version} -f
      diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/vue-cli-diff/compare/${lastVersion}...${version})"
      git checkout master
      # rewrite stats in README after rebase
      sed -i "" "/^${version}|/ d" README.md
      sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
      sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
      git commit -a --amend --no-edit
      git push origin master -f
      git checkout ${version}
    fi
    lastVersion=${version}
    continue
  fi

  echo "Generate ${version}"
  rebaseNeeded=true
  git checkout -b ${version}
  # delete app
  rm -rf ponyracer
  # generate app with new CLI version
  npx @vue/cli@${version} create ponyracer  -m npm -r https://registry.npmjs.org --inlinePreset '{"useConfigFiles": true,"plugins": {"@vue/cli-plugin-typescript": {"classComponent": false},"@vue/cli-plugin-eslint": {"config": "prettier","lintOn": ["save"]},"@vue/cli-plugin-unit-jest": {},"@vue/cli-plugin-e2e-cypress": {}}}'
  rm ponyracer/package-lock.json
  git add ponyracer
  git commit --allow-empty -am "chore: version ${version}"
  diffStat=`git --no-pager diff HEAD~ --shortstat`
  git push origin ${version} -f
  git checkout master
  diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/vue-cli-diff/compare/${lastVersion}...${version})"
  # insert a row in the version table of the README
  sed -i "" "/^${version}|/ d" README.md
  sed -i '' 's/----|----|----/----|----|----\
NEWLINE/g' README.md
  sed -i "" "s@NEWLINE@${version}|${diffUrl}|${diffStat}@" README.md
  # commit
  git commit -a --amend --no-edit
  git checkout ${version}
  lastVersion=${version}

done

git checkout master
git push origin master -f
