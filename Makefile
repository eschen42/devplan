default_goal: README.md

# rule to update README.md
README.md: Dockerfile use_cases/devplan_bootstrap
	sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$$//; p' Dockerfile use_cases/devplan_bootstrap > README.md

# rule to push git changes
push:
	test 0 -eq `git status --porcelain | grep -v '^[?][?]' | wc -l`
	git push

# vim: noet :