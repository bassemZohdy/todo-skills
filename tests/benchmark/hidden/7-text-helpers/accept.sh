# Scenario 7: one check line per function of the requirement (so a result shows which of the four were built), and one line for the
# agent's tests: they pass, and they fail when any one of the four modules is replaced by a stub whose function raises NotImplementedError.
. "$(dirname "$0")/../lib.sh"
# hidden_class <class>: only that class of test_accept.py passes (each class imports only its own function).
hidden_class() { (cd "$repo" && py "$hid/test_accept.py" "$1") > "$repo.hidden-$1.log" 2>&1; local rc=$?; sed 's/^/    /' "$repo.hidden-$1.log" | tail -20; return $rc; }
# tests_cover_each: the agent's tests pass (the start runs 2 tests, so any new test counts) and each stub makes them fail; all are run, so the log shows every module.
tests_cover_each() { local bad=0 m; agent_tests_pass 3 || bad=1
  for m in slug wrap counts rows; do fails_with_file "textkit/$m.py" "$hid/stub_$m.py" || bad=1; done; [ "$bad" -eq 0 ]; }
check "feature slugify (textkit.slug): the hidden tests pass" hidden_class SlugAccept
check "feature wrap (textkit.wrap): the hidden tests pass" hidden_class WrapAccept
check "feature top_words (textkit.counts): the hidden tests pass" hidden_class TopWordsAccept
check "feature parse_row (textkit.rows): the hidden tests pass" hidden_class ParseRowAccept
check "the agent's tests cover each function" tests_cover_each
finish
