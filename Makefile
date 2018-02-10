## # Makefile automation
##
## To build and smoke-test the Docker image locally:
## ```
## make test_image
## ```
##
## To smoke-test [the `eschen42/devplan:alpha` image from hub.docker.com](https://hub.docker.com/r/eschen42/devplan/tags/):
## ```
## make test_alpha
## ```
##
## To update README.md:
## ```
## make
## ```
##
## To push changes to origin (after checking for uncommited changes):
## ```
## make push
## ```

# rule to update README.md
README.md: Dockerfile use_cases/devplan_bootstrap
	sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$$//; p' Dockerfile Makefile use_cases/devplan_bootstrap > README.md

# rule to push git changes
push:
	test 0 -eq `git status --porcelain | grep -v '^[?][?]' | wc -l`
	git push

# rule to get unit testing "framework"
bashunit:
	if [ ! -f use_cases/bashunit.bash ]; then wget -O use_cases/bashunit.bash https://raw.githubusercontent.com/eschen42/bashunit/master/bashunit.bash; fi

# run tests on eschen42/devplan:alpha tag from docker hub
test_alpha: bashunit
	pushd use_cases > /dev/null; ./alpha_test --lineshow

# run tests on image built locally
test_image: bashunit
	pushd use_cases > /dev/null; ./image_test --lineshow

# vim: noet :
