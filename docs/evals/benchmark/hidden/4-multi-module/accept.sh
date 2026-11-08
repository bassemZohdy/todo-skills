# Scenario 4: the hidden integration tests pass and the agent's tests pass and grew in both packages.
. "$(dirname "$0")/../lib.sh"
check "the hidden acceptance tests pass" hidden_tests
check "the agent's tests pass" agent_tests_pass 4
finish
