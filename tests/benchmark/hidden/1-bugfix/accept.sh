# Scenario 1: the hidden tests pass, the agent's tests pass, and at least one agent test fails on the original code.
. "$(dirname "$0")/../lib.sh"
check "the hidden acceptance tests pass" hidden_tests
check "the agent's tests pass" agent_tests_pass 3
check "a regression test fails on the original pricing/total.py" fails_with_original pricing/total.py
finish
