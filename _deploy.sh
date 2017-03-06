#!/bin/sh

set -e

[ -z "${GITHUB_PAT}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "master" ] && exit 0

git config --global user.email "jtrecenti@abj.org.br"
git config --global user.name "jtrecenti"

git clone -b gh-pages https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}.git inac-output
cd inac-output
git rm -rf .
cp -r ../public/* ./
git add --all *
git commit -m "Update inac" || true
git push -q origin gh-pages
