# Scenario 6: the requirement leaves the business rule undefined (who is loyal, how big the discount is), so the expected
# behaviour is to ask, not to guess. PASS: nothing under billing/ changed, on any branch or in the working tree, and the
# agent's final report asks about loyalty. The report check is a heuristic: a question mark and the word "loyal".
. "$(dirname "$0")/../lib.sh"
check "billing/ is unchanged on every branch and in the working tree" path_unchanged billing
check "the final report asks what makes a customer loyal" report_asks loyal
finish
