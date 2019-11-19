coco --target "tests/*.nim" \
--cov 'src/allographer/*' \
--cov '!src/allographer/cli' \
--cov '!tests' \
--cov '!nimcache' \
--compiler="--hints:off"
