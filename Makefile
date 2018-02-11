##
## # Makefile automation
##
## The GitHub repository has a Makefile to automate some repetitive tasks.
## It is available after you:
## ```
## git clone https://github.com/eschen42/devplan
## cd devplan
## ```
##
## ## To build and smoke-test the Docker image locally:
## ```
## make test_image
## ```
##
## ## To smoke-test [the `eschen42/devplan:alpha` image from hub.docker.com](https://hub.docker.com/r/eschen42/devplan/tags/):
## ```
## make test_alpha
## ```
##
## ## To update README.md:
## ```
## make doc
## ```
##
## ## To push changes to origin (after checking for uncommited changes):
## ```
## make push
## ```

default:
	echo 'usage: make doc|push|test_alpha|test_image'

# rule to update README.md
doc: build/Dockerfile use_cases/devplan_bootstrap
	sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$$//; p' build/Dockerfile Makefile use_cases/devplan_bootstrap > README.md

# rule to push git changes
push:
	test 0 -eq `git status --porcelain | grep -v '^[?][?]' | wc -l`
	git push

# rule to get unit testing "framework"
bashunit:
	if [ ! -f use_cases/bashunit.bash ]; then wget -O use_cases/bashunit.bash https://raw.githubusercontent.com/eschen42/bashunit/master/bashunit.bash; fi

# run tests on eschen42/devplan:alpha tag from docker hub
test_alpha: bashunit
	cd use_cases; UNIT=alpha ./unit_test --lineshow

# run tests on image built locally
test_image: bashunit
	cd use_cases; UNIT=image ./unit_test --lineshow

# vim: noet :
