#!/usr/bin/env bash
# Run all ccb unit tests.
#
# Works with:
#   * the portable, user-space Ruby under ~/ruby-ut (no root needed), or
#   * a normal system Ruby that already has `minitest` installed.
#
# Usage:
#   ./test/run_tests.sh            # run the whole suite
#   ./test/run_tests.sh <file>     # run a single file, e.g. test/test_opt_parse.rb
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PORTABLE_ROOT="$HOME/ruby-ut/root"

if [ -x "$PORTABLE_ROOT/usr/bin/ruby" ]; then
  export LD_LIBRARY_PATH="$PORTABLE_ROOT/usr/lib64:${LD_LIBRARY_PATH:-}"
  export RUBYLIB="$PORTABLE_ROOT/usr/share/rubygems:$PORTABLE_ROOT/usr/share/ruby:$PORTABLE_ROOT/usr/lib64/ruby"
  export GEM_HOME="$PORTABLE_ROOT/usr/share/gems"
  export GEM_PATH="$PORTABLE_ROOT/usr/share/gems:$PORTABLE_ROOT/usr/lib64/gems:$PORTABLE_ROOT/usr/local/share/gems"
  RUBY="$PORTABLE_ROOT/usr/bin/ruby"

  RELOCATE="$(mktemp --suffix=.rb)"
  trap 'rm -f "$RELOCATE"' EXIT
  cat > "$RELOCATE" <<'RB'
require "rbconfig"
p = ENV["UT_ROOT"]
if p
  c = RbConfig::CONFIG
  c["vendordir"] = "#{p}/usr/share/ruby/vendor_ruby"
  c["sitedir"]   = "#{p}/usr/local/share/ruby/site_ruby"
  c["libdir"]    = "#{p}/usr/lib64"
  c["bindir"]    = "#{p}/usr/bin"
end
RB
  export UT_ROOT="$PORTABLE_ROOT"
  export RUBYOPT="--disable-gems -r$RELOCATE -rrubygems"
else
  RUBY="$(command -v ruby)"
fi

if [ "$#" -ge 1 ]; then
  exec "$RUBY" -Itest "$@"
fi

exec "$RUBY" -Itest -e 'Dir.glob("test/test_*.rb").sort.each { |f| require File.expand_path(f) }'
