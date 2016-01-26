#!/usr/bin/env bash
set -eux

DIGEST=`git ls-tree HEAD -- cider-ci/bin/precompile-assets-with-caching.sh config app/assets Gemfile.lock package.json | openssl dgst -sha1 | cut -d ' ' -f 2`

ASSETS_CACHE_DIR="/tmp/assets_${DIGEST}"
if [ -d "$ASSETS_CACHE_DIR" ]; then
  echo "assets cache exists, just linking..."
else
  bundle exec rake assets:precompile
  mv public/admin/assets "${ASSETS_CACHE_DIR}"
fi
if [ ! -d public/admin ]; then
  mkdir public/admin
fi
ln -s "$ASSETS_CACHE_DIR" public/admin/assets