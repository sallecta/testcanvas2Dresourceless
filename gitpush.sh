#!/bin/bash

echo Enter commit message:
read commmitMessage
if [ "$commmitMessage" = "" ]
then
    commmitMessage='...'
fi
echo commit message is \"$commmitMessage\"

git add *
git status
git commit --message="$commmitMessage"
git push
