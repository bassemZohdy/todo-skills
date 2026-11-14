# Scenario 2: the hidden tests pass and the agent added passing tests (more than the one it was given).
. "$(dirname "$0")/../lib.sh"
check "the hidden acceptance tests pass" hidden_tests
check "the agent's tests pass and cover the new cases" agent_tests_pass 3
finish
