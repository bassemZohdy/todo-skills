# Scenario 3: the hidden tests pass, the agent's tests pass, and they fail on a permissive verify() that accepts anything
# (so they contain negative cases).
. "$(dirname "$0")/../lib.sh"
check "the hidden acceptance tests pass" hidden_tests
check "the agent's tests pass" agent_tests_pass 3
check "the agent's tests reject a permissive verify()" fails_with_file auth/tokens.py "$hid/permissive_tokens.py"
finish
