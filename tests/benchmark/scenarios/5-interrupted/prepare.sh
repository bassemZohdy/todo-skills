# Scenario 5 (run by the controller after the start commit): leave the repository as an interrupted session would,
# with a work-in-progress commit and an uncommitted change on top of it. Usage: bash prepare.sh <repo>
set -eu
cd "$1"
printf 'def slugify(text):\n    return text.lower()\n' > textutil/slug.py
printf 'import unittest\n\nfrom textutil.slug import slugify\n\n\nclass SlugTest(unittest.TestCase):\n    def test_lowercases(self):\n        self.assertEqual(slugify("Hello"), "hello")\n' > tests/test_slug.py
git add textutil/slug.py tests/test_slug.py
git -c user.name=wip -c user.email=wip@example.invalid commit -qm "wip: slugify lowercases"
printf 'import re\n\n\ndef slugify(text):\n    text = text.lower()\n    return text.replace(" ", "-")\n' > textutil/slug.py
