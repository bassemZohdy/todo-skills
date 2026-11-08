# Scenario 5: the hidden tests pass, the agent's tests pass, and the interrupted session's commit is still on a branch.
. "$(dirname "$0")/../lib.sh"
check "the hidden acceptance tests pass" hidden_tests
check "the agent's tests pass" agent_tests_pass 2
check "the work-in-progress commit is still on a branch" commit_kept "$start"
finish
