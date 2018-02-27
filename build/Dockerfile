# vim: sw=2 ts=2 et :
## [![DOI](https://zenodo.org/badge/118467922.svg)](https://zenodo.org/badge/latestdoi/118467922)
##
## # devplan: a Docker image for RStudio and Planemo development
##
## This image provides for Planemo development and RStudio package development:
##
##   - R 3.4.1
##   - RStudio 1.1, using R 3.4.1.
##   - The R package `devtools` for package development, including vignette-building capability.
##   - The lastest version of Planemo (currently 0.47.0) for development and testing of Galaxy tool wrappers.
##   - Extra support for running a local tool shed with the container to test creating and updating tools in the tool shed.
##   - Extra support for running `planemo serve` to test a tool wrapper and see the effect of changes "live".
##   - Extra support for running `planemo shed_serve` to test installability Galaxy of tools from a tool shed.
##
## # Motivation
##
## I develop R packages in RStudio using the devtools R library, and then I use Planemo to wrap them as Galaxy tools.  This has presented a few challenges:
##
##   - I want to keep the version of R with which I built a package in sync with the bioconda package dependency in the declaration of the Galaxy wrapper.
##   - I want an environment in which I
##     - can develop and test my R packages,
##     - can develop and test Galaxy wrappers,
##     - can test adding or updating the wrapper in a Galaxy tool shed, without resorting to using the public test tool shed,
##     - can validate that my tool as deployed to a tool shed will successfully install in a Galaxy instance, without resorting to using the public test tool shed.
##   - I have found myself recurrently creating a development environment customized for my use on several machines and operating systems.
##     - The versions and behaviors of the various tools, some of which are fairly complex, drifts significantly among my installations.
##     - I have had times in the past when the version R installed with RStudio was ahead of `r-base` in bioconda.
##   - I therefore wanted a Docker image that will run the same way everywhere,
##     so that I can focus on my work without wasting much effort adapting to the platform on which I am working at the moment.
##
## I therefore developed this Docker image to bring together into one place functionality that I have not found in an image available elsewhere.
##   - Points of departure:
##     - The base Docker image is rocker/verse:3.4.1, which allows me to make sure that I will always be building packages that target that version.
##       - When I want to use a newer version of R, I will rebuild the image.
##     - The planemo/interactive Docker image is great, but I would like to have everything in a single image
##       rather than using docker-compose to map ports and volumes among several images.
##       - That approach is quite viable, but it adds complexity that is not easy to explain to others.
##     - No image can ever have all the utilities that one individual has come to rely upon, so I have added some of my favorites.
##
## # Quick Start
##
## - Start the docker container with the latest alpha (unstable) version:
## ```
## # fetch the bootstrap scripts
## git clone https://github.com/eschen42/devplan
## # change to the directory where the bootstrap scripts are located
## cd devplan/use_cases
## # set this to any password that you prefer
## PASSWORD=password.to.log.into.rstudio.server
## # set up the docker container and home directory
## source devplan_bootstrap localhost.example
## # run the container
## run_docker_rstudio
## ```
## - Browse to http://localhost:8587 
##   - log in as user `rstudio` with the password that you set above. 
## - Build R packages from the Console tab in RStudio
## - Run commands from the Terminal tab in RStudio:
##   - [Start your own toolshed with `/run_shed`](#step-10---browsing-local-tool-shed)
##   - [Run `planemo test`](#step-6---using-planemo-from-the-guest-command-line)
##   - [Run `planemo serve`](#step-9---running-planemo-serve)
##   - [Create a repository for your tool in your local toolshed with `planemo shed_create` and test the repository with `planemo shed_serve`](#step-11---browsing-results-for-planemo-shed_serve)
##
## # How to use this Docker image
##
## ## Step 1 - Get or build an image
##
## ### To use a pre-built image
##
## If you would like to use a pre-built image you can find a tagged release at [https://hub.docker.com/r/eschen42/devplan/tags/](https://hub.docker.com/r/eschen42/devplan/tags/) and pull with
## ```
##     docker pull eschen42/devplan:put-the-tag-here
## ```
##
## *You can now proceed to Step 2.*  However, remember to supply the name of your image including the tag anywhere below that the instructions say `eschen42/devplan`.
##
## ### To build a customized image
##
## #### Choose an R version
##    - Choose an R version supported by bioconda and choose the corresponding version of rocker/verse, e.g.
##    ```
##        conda search r-base
##    ```
##
## #### Build your own image from the Dockerfile
##    - Build from this Dockerfile (you must cd to the directory containing it first)
##    ```
##        docker build -t eschen42/devplan .
##    ```
##
## ## Step 2 - Create a persistent home directory
##    - Create a directory on the host to persist changes to `/home/rstudio` on the guest, e.g.:
##    ```
##        mkdir ~/rstudio
##    ```
##    - Important: Files created within `/home/rstudio` on the guest will be owned by the owner of (and have the same group as) this directory.
##      -  Make sure that you adjust the userid and groupid of this directory with `chown` *before* you perform step 3.
##
## ## Step 3 - Run a new container instance from the image
##    - Run the container with this directory; note that the container will create files
##      in this directory with UID 1000 (which is user rstudio on the guest), e.g.:
##    ```
##        # docker run       - create a new docker container
##        #   --name devplan -   nicknamed devplan
##        #   --rm           -   automatic clean-up when container stops
##        #   -ti            -   allow interaction with the keyboard
##        #   -p 8787:8787   -   allow connection on localhost port 8787 to connect to Rstudio in the container 
##        #   -p 8790:8790   -   allow connection on localhost port 8790 to planemo serve and planemo shed_serve
##        #   -p 8709:8709   -   allow connection on localhost port 8709 to a local instance of Galaxy toolshed
##        #   -v ~/rstudio:/home/rstudio
##        #                  - share host folder ~/rstudio within the container as /home/rstudio
##        #   eschen42/devplan (or docker pull eschen42/devplan:put-the-tag-here)
##        #                  -   run this docker image
##        docker run --name devplan --rm -ti -p 8787:8787 -p 8790:8790 -p 8709:8709 -v ~/rstudio:/home/rstudio eschen42/devplan
##    ```
##    - At this point you can use RStudio; see Step 8 below.
##    - In fact, you can use the terminal interface within Rstudio (`Tools > Terminal > New Terminal`) to complete the following steps.
##    - After you exit the container, the next time you run this `docker run` command, `/home/rstudio` on the guest will have your files and history.
##    - To experiment *without* persisting changes, omit the `-v ~/rstudio:/home/rstudio` option.
##
## ## Step 4 - Set up the rstudio home directory
##    - **Important:** *Perform this and all subsequent steps running as user `rstudio`.*
##    - When you get to the command line using the invocation in step 3, you will be logged in as user `rstudio`.
##    - Run this script:
##    ```
##         /setup_home
##    ```
##    - The script essentially does the equivalent of the following:
##    ```
##         virtualenv ~/venv      # create a virtual environment
##         . ~/venv/bin/activate  # make the environment active
##         pip install planemo    # install planemo
##         planemo conda_init     # set up conda in ~/miniconda3
##    ```
##
## ## Step 5 - Set up .ssh and git
##    - Set up /home/rstudio/.ssh (on the guest; ~/devplan/.ssh on the host) if desired
##      and make sure that the permissions are right (For further info, see: https://superuser.com/a/215506)
##    - Set up git global variables
##    ```
##         git config --global --add user.name "John Doe"
##         git config --global --add user.email "jdoe@example.net"
##    ```
##
## ## Step 6 - Using Planemo from the guest command line
##    - Working on the guest:
##        - Run the following unless you have already activated the venv:
##        ```
##             . ~/venv/bin/activate
##        ```
##        - Clone the wrapper project you want to work with and cd to it.
##        - Run the following the first time you run planemo and each time you change the conda dependencies:
##        ```
##             planemo conda_install .
##        ```
##        - Run the following to test the wrapper:
##        ```
##             planemo test --conda_dependency_resolution .
##        ```
##        - Once tests are passing, you can run `planemo serve`: see [Step 9](#step-9---running-planemo-serve)
##
## ## Step 7 - Setting up the `localshed` tool shed
## You can set up a local instance of the Galaxy tool shed; this requires a moderate amount of manual effort:
##   - To begin, run the command to set up the shed, along with a port for the web server "listener" and your email address, e.g.:
##        ```
##             /setup_shed --port 8709 --admin admin@galaxy.org
##        ```
##   - *Note well*: You will most likely want to access your tool shed through the browser as "localhost" on the same port as
##     the tool shed server is listening to in the container.  At some point, you may want to install to an instance of Galaxy
##     running in your container, using the administrative interface of the Galaxy web interface; because the tool shed and the
##     web interact by passing the URL of the toolshed back and forth, you can avoid some "broken" URLs this way. 
##
## ## Step 8 - Running RStudio
##    - On the host, browse to RStudio at http://localhost:8787
##    - Log into RStudio as user `rstudio` with password `rstudio`
##
## ## Step 9 - Running `planemo serve`
##    - One great thing about `planemo serve` is that you can see changes to your tool wrapper "live":
##      - You can edit the tool in your tool directory, then click the tool name in the tool frame on
##        the left side of your browser and see the effect immediately.
##    - On the guest,
##      - `cd` to the directory with the source code for your Galaxy tool;
##      - run the `/run_planemo_serve` convenience script
##        - or, run `planemo serve` with the parameters of your choice, e.g.:
##            ```
##              planemo serve --port 8790 --host 0.0.0.0 --conda_dependency_resolution .
##            ```
##    - On the host,
##      - browse to the `planemo serve` instance at http://localhost:8790
##
## ## Step 10 - Browsing local tool shed
##    - On the guest, execute `/run_shed` and make note of the process ID in case you will need to shut down the tool shed.
##      - For instance, suppose it starts with PID 243.
##    - On the host, browse to http://localhost:8709
##    - To shut down the tool shed, on the guest, execute `/kill_group`
##      - For the example above, run `/kill_group --pid 243`
##
## ## Step 11 - Browsing results for `planemo shed_serve`
##    - On the guest,
##      - make sure that you started the tool shed, as described in Step 10.
##        - Make note of the process ID in case you want to shut it down later.
##        - For instance, suppose it starts with PID 442.
##      - make sure that you have added the category for your tool via the shed admin menu.
##      - make sure that you have added the repository for at least one tool to the toolshed, e.g.:
##          ```
##              planemo shed_create -t localshed --name my_new_tool .
##          ```
##         - an empty tooshed causes an error with `planemo shed_serve`
##      - run `/run_planemo_shed_serve -t localshed`
##        - or, run `planemo shed_serve` with the parameters of your choice, e.g.:
##            ```
##              planemo shed_serve -t localshed --port 8790 \
##                --galaxy_root /home/rstudio/shed/galaxyproject-galaxy/ \
##                --host 0.0.0.0 --conda_dependency_resolution .
##            ```
##        - You will either have to make sure that `planemo serve` is not running
##          or run `planemo shed_serve` on a different port.
##    - On the host, browse to the `planemo shed_serve` instance at http://localhost:8790
##      - For the example above, run `kill -TERM 442`
##
## # Customization
##
## If you prefer `emacs` as your editor, you will want to:
##   - modify or extend the Dockerfile to install the desired emacs packages
##   - append the something like following to `/home/rstudio/profile` in the guest or modify `setup_home` accordingly:
##     ```
##        # this is not validated becasue I don't use emacs
##        EDITOR=emacs; export EDITOR
##        # turn off vi-mode command-line editing-behavior
##        set +o vi
##        # turn on emacs-mode command-line editing-behavior
##        set -o emacs
##     ```
##
## If you prefer `nano` as your editor, you will want to:
##   - modify or extend the Dockerfile to install the desired nano packages
##   - append the something like following to `/home/rstudio/profile` in the guest or modify `setup_home` accordingly:
##     ```
##        # this is not validated becasue I don't use nano
##        EDITOR=nano; export EDITOR
##        # turn off vi-mode command-line editing-behavior
##        set +o vi
##     ```

# To view the header of this Dockerfile as markdown, run `sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$//; p' Dockerfile`

# rocker/verse@sha256:b0132579bd5dac31b989bbbb2a78aee8616099622257edd3bc6ae70a1ee97c59
#   is the Docker image that was tagged rocker/verse:3.4.1 as of January, 2018.
#   It was built around RStudio 1.1 and R 3.4.1.
#   In February, this tag changed to use RStudio 1.0 instead.
#     https://github.com/rocker-org/rocker-versioned/pull/69
#   Because I started with RStudio 1.1 (which only came out nine days after R 3.4.1 was released),
#   and because the UI for 1.1 has 'Terminal' rather than 'Shell', 
#   I am pinning the base of my build to the January, 2018 version.
FROM rocker/verse@sha256:b0132579bd5dac31b989bbbb2a78aee8616099622257edd3bc6ae70a1ee97c59
# was FROM rocker/verse:3.4.1
MAINTAINER Arthur C. Eschenlauer, esch0041@umn.edu

RUN apt-get update

# texlive-common includes both texlive-science and texlive-latex-extra
RUN apt-get install -y texlive-common

# Set up some utilities that I don't want to be without
RUN apt-get -y install bzip2 curl wget vim-tiny screen
RUN update-alternatives --install /usr/bin/vim vim /usr/bin/vim.tiny 10
RUN apt-get -y install net-tools bind9-host dnsutils
RUN apt-get -y install locales gawk debconf git
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
RUN apt-get -y install procps
RUN apt-get -y install build-essential

# This is needed for ssh-access to GitHub
RUN apt-get -y install openssh-client

# This is needed for planemo under pip
RUN apt-get -y install virtualenv

# Set shell for user 'rstudio' to bash
RUN sed -i -e '/rstudio:$/ s/:$/:\/bin\/bash/' /etc/passwd

# optional - install man pages (comment out the next line if you don't want them)
RUN apt-get -y install man-db manpages manpages-dev

# optional - sharutils provides shar
RUN  apt-get -y install sharutils

# experimental: Run an sshd server for remote access/X - this only can work when /run/sshd exists
RUN  apt-get -y install openssh-server openssh-sftp-server
RUN  mkdir /run/sshd
RUN apt-get -y install xauth xterm xtermcontrol perl-tk

# optional - install lyx
RUN apt-get -y install lyx

# In rocker/verse, /init starts up s6 services.
# Define the fixid1 "service" that runs once, changing UID and GID of 'rstudio' user to match those of /home/rstudio
RUN  mkdir /etc/services.d/fixid1k
COPY fixid1k_run /etc/services.d/fixid1k/run
RUN  chmod u+x /etc/services.d/fixid1k/run
# Copy the script to set up the home directory
COPY setup_home /setup_home
RUN  bash -c 'chmod +x /setup_home'
# Copy the script to set up the localshed local tool shed
COPY setup_shed /setup_shed
RUN  bash -c 'chmod +x /setup_shed'
# Copy the script to invoke the previous two
COPY setup_homeshed /setup_homeshed
RUN  bash -c 'chmod +x /setup_homeshed'
# Copy the script to run the localshed local tool shed
COPY run_shed /run_shed
RUN  bash -c 'chmod +x /run_shed'
# Copy the script to run planemo shed_serve
COPY run_planemo_shed_serve /run_planemo_shed_serve
RUN  bash -c 'chmod +x /run_planemo_shed_serve'
# Copy the script to run planemo serve
COPY run_planemo_serve /run_planemo_serve
RUN  bash -c 'chmod +x /run_planemo_serve'
# Copy the script to kill all members of a process group
COPY kill_group /kill_group
RUN  bash -c 'chmod +x /kill_group'
# Copy the sshd_config file to root directory
COPY sshd_config /sshd_config
RUN  bash -c 'chmod 644 /sshd_config'

COPY Dockerfile /Dockerfile
