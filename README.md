[![DOI](https://zenodo.org/badge/118467922.svg)](https://zenodo.org/badge/latestdoi/118467922)

# devplan: a Docker image for RStudio and Planemo development

This image provides for Planemo development and RStudio package development:

  - R 3.4.1
  - RStudio 1.1, using R 3.4.1.
  - The R package `devtools` for package development, including vignette-building capability.
  - The lastest version of Planemo (currently 0.47.0) for development and testing of Galaxy tool wrappers.
  - Extra support for running a local tool shed with the container to test creating and updating tools in the tool shed.
  - Extra support for running `planemo serve` to test a tool wrapper and see the effect of changes "live".
  - Extra support for running `planemo shed_serve` to test installability Galaxy of tools from a tool shed.

# Motivation

I develop R packages in RStudio using the devtools R library, and then I use Planemo to wrap them as Galaxy tools.  This has presented a few challenges:

  - I want to keep the version of R with which I built a package in sync with the bioconda package dependency in the declaration of the Galaxy wrapper.
  - I want an environment in which I
    - can develop and test my R packages,
    - can develop and test Galaxy wrappers,
    - can test adding or updating the wrapper in a Galaxy tool shed, without resorting to using the public test tool shed,
    - can validate that my tool as deployed to a tool shed will successfully install in a Galaxy instance, without resorting to using the public test tool shed.
  - I have found myself recurrently creating a development environment customized for my use on several machines and operating systems.
    - The versions and behaviors of the various tools, some of which are fairly complex, drifts significantly among my installations.
    - I have had times in the past when the version R installed with RStudio was ahead of `r-base` in bioconda.
  - I therefore wanted a Docker image that will run the same way everywhere,
    so that I can focus on my work without wasting much effort adapting to the platform on which I am working at the moment.

I therefore developed this Docker image to bring together into one place functionality that I have not found in an image available elsewhere.
  - Points of departure:
    - The base Docker image is rocker/verse:3.4.1, which allows me to make sure that I will always be building packages that target that version.
      - When I want to use a newer version of R, I will rebuild the image.
    - The planemo/interactive Docker image is great, but I would like to have everything in a single image
      rather than using docker-compose to map ports and volumes among several images.
      - That approach is quite viable, but it adds complexity that is not easy to explain to others.
    - No image can ever have all the utilities that one individual has come to rely upon, so I have added some of my favorites.

# Quick Start

- Start the docker container with the latest alpha (unstable) version:
```
git clone https://github.com/eschen42/devplan
cd devplan/use_cases
source devplan_bootstrap localhost.example
run_docker_rstudio
```
- Browse to http://localhost:8587 
- Build R packages from the Console tab in RStudio
- Run Planemo commands from the Terminal tab in RStudio

# How to use this Docker image

## Step 1 - Get or build an image

### To use a pre-built image

If you would like to use a pre-built image you can find a tagged release at [https://hub.docker.com/r/eschen42/devplan/tags/](https://hub.docker.com/r/eschen42/devplan/tags/) and pull with
```
    docker pull eschen42/devplan:put-the-tag-here
```

*You can now proceed to Step 2.*  However, remember to supply the name of your image including the tag anywhere below that the instructions say `eschen42/devplan`.

### To build a customized image

#### Choose an R version
   - Choose an R version supported by bioconda and choose the corresponding version of rocker/verse, e.g.
   ```
       conda search r-base
   ```

#### Build your own image from the Dockerfile
   - Build from this Dockerfile (you must cd to the directory containing it first)
   ```
       docker build -t eschen42/devplan .
   ```

## Step 2 - Create a persistent home directory
   - Create a directory on the host to persist changes to `/home/rstudio` on the guest, e.g.:
   ```
       mkdir ~/rstudio
   ```
   - Important: Files created within `/home/rstudio` on the guest will be owned by the owner of (and have the same group as) this directory.
     -  Make sure that you adjust the userid and groupid of this directory with `chown` *before* you perform step 3.

## Step 3 - Run a new container instance from the image
   - Run the container with this directory; note that the container will create files
     in this directory with UID 1000 (which is user rstudio on the guest), e.g.:
   ```
       # docker run       - create a new docker container
       #   --name devplan -   nicknamed devplan
       #   --rm           -   automatic clean-up when container stops
       #   -ti            -   allow interaction with the keyboard
       #   -p 8787:8787   -   allow connection on localhost port 8787 to connect to Rstudio in the container 
       #   -p 8790:8790   -   allow connection on localhost port 8790 to planemo serve and planemo shed_serve
       #   -p 8709:8709   -   allow connection on localhost port 8709 to a local instance of Galaxy toolshed
       #   -v ~/rstudio:/home/rstudio
       #                  - share host folder ~/rstudio within the container as /home/rstudio
       #   eschen42/devplan (or docker pull eschen42/devplan:put-the-tag-here)
       #                  -   run this docker image
       docker run --name devplan --rm -ti -p 8787:8787 -p 8790:8790 -p 8709:8709 -v ~/rstudio:/home/rstudio eschen42/devplan
   ```
   - At this point you can use RStudio; see Step 8 below.
   - In fact, you can use the terminal interface within Rstudio (`Tools > Terminal > New Terminal`) to complete the following steps.
   - After you exit the container, the next time you run this `docker run` command, `/home/rstudio` on the guest will have your files and history.
   - To experiment *without* persisting changes, omit the `-v ~/rstudio:/home/rstudio` option.

## Step 4 - Set up the rstudio home directory
   - **Important:** *Perform this and all subsequent steps running as user `rstudio`.*
   - When you get to the command line using the invocation in step 3, you will be logged in as user `rstudio`.
   - Run this script:
   ```
        /setup_home
   ```
   - The script essentially does the equivalent of the following:
   ```
        virtualenv ~/venv      # create a virtual environment
        . ~/venv/bin/activate  # make the environment active
        pip install planemo    # install planemo
        planemo conda_init     # set up conda in ~/miniconda3
   ```

## Step 5 - Set up .ssh and git
   - Set up /home/rstudio/.ssh (on the guest; ~/devplan/.ssh on the host) if desired
     and make sure that the permissions are right (For further info, see: https://superuser.com/a/215506)
   - Set up git global variables
   ```
        git config --global --add user.name "John Doe"
        git config --global --add user.email "jdoe@example.net"
   ```

## Step 6 - Using Planemo from the guest command line
   - Working on the guest:
       - Run the following unless you have already activated the venv:
       ```
            . ~/venv/bin/activate
       ```
       - Clone the wrapper project you want to work with and cd to it.
       - Run the following the first time you run planemo and each time you change the conda dependencies:
       ```
            planemo conda_install .
       ```
       - Run the following to test the wrapper:
       ```
            planemo test --conda_dependency_resolution .
       ```
       - Once tests are passing, run the following to serve the tool:
       ```
            planemo serve --host 0.0.0.0 --conda_dependency_resolution .
       ```
       - Because you can live-edit your tool and wrapper, you may find it more convenient
         to have a daemon serve the current directory:
       ```
            planemo serve --daemon --host 0.0.0.0 --conda_dependency_resolution .
            # or, equivalently
            /run_planemo_shed_serve
       ```

## Step 7 - Setting up the `localshed` tool shed
You can set up a local instance of the Galaxy tool shed; this requires a moderate amount of manual effort:
  - To begin, run the command to set up the shed, along with a port for the web server "listener" and your email address, e.g.:
       ```
            /setup_shed --port 8709 --admin admin@galaxy.org
       ```
  - *Note well*: You will most likely want to access your tool shed through the browser as "localhost" on the same port as
    the tool shed server is listening to in the container.  At some point, you may want to install to an instance of Galaxy
    running in your container, using the administrative interface of the Galaxy web interface; because the tool shed and the
    web interact by passing the URL of the toolshed back and forth, you can avoid some "broken" URLs this way. 

## Step 8 - Running RStudio
   - On the host, browse to RStudio at http://localhost:8787
   - Log into RStudio as user `rstudio` with password `rstudio`

## Step 9 - Running `planemo serve`
   - One great thing about `planemo serve` is that you can see changes to your tool wrapper "live":
     - You can edit the tool in your tool directory, then click the tool name in the tool frame on
       the left side of your browser and see the effect immediately.
   - On the guest,
     - `cd` to the directory with the source code for your Galaxy tool;
     - run the `/run_planemo_serve` convenience script
       - or, run `planemo serve` with the parameters of your choice, e.g.:
           ```
             planemo serve --port 8790 --host 0.0.0.0 --conda_dependency_resolution .
           ```
   - On the host,
     - browse to the `planemo serve` instance at http://localhost:8790

## Step 10 - Browsing local tool shed
   - On the guest, execute `/run_shed` and make note of the process ID in case you will need to shut down the tool shed.
     - For instance, suppose it starts with PID 243.
   - On the host, browse to http://localhost:8709
   - To shut down the tool shed, on the guest, execute `/kill_group`
     - For the example above, run `/kill_group --pid 243`

## Step 11 - Browsing results for `planemo shed_serve`
   - On the guest,
     - make sure that you started the tool shed, as described in Step 10.
       - Make note of the process ID in case you want to shut it down later.
       - For instance, suppose it starts with PID 442.
     - make sure that you have added the category for your tool via the shed admin menu.
     - make sure that you have added the repository for at least one tool to the toolshed, e.g.:
         ```
             planemo shed_create -t localshed --name my_new_tool .
         ```
        - an empty tooshed causes an error with `planemo shed_serve`
     - run `/run_planemo_shed_serve -t localshed`
       - or, run `planemo shed_serve` with the parameters of your choice, e.g.:
           ```
             planemo shed_serve -t localshed --port 8790 \
               --galaxy_root /home/rstudio/shed/galaxyproject-galaxy/ \
               --host 0.0.0.0 --conda_dependency_resolution .
           ```
       - You will either have to make sure that `planemo serve` is not running
         or run `planemo shed_serve` on a different port.
   - On the host, browse to the `planemo shed_serve` instance at http://localhost:8790
     - For the example above, run `kill -TERM 442`

# Customization

If you prefer `emacs` as your editor, you will want to:
  - modify or extend the Dockerfile to install the desired emacs packages
  - append the something like following to `/home/rstudio/profile` in the guest or modify `setup_home` accordingly:
    ```
       # this is not validated becasue I don't use emacs
       EDITOR=emacs; export EDITOR
       # turn off vi-mode command-line editing-behavior
       set +o vi
       # turn on emacs-mode command-line editing-behavior
       set -o emacs
    ```

If you prefer `nano` as your editor, you will want to:
  - modify or extend the Dockerfile to install the desired nano packages
  - append the something like following to `/home/rstudio/profile` in the guest or modify `setup_home` accordingly:
    ```
       # this is not validated becasue I don't use nano
       EDITOR=nano; export EDITOR
       # turn off vi-mode command-line editing-behavior
       set +o vi
    ```

# Makefile automation

The GitHub repository has a Makefile to automate some repetitive tasks.
It is available after you:
```
git clone https://github.com/eschen42/devplan
cd devplan
```

## To build and smoke-test the Docker image locally:
```
make test_image
```

## To smoke-test [the `eschen42/devplan:alpha` image from hub.docker.com](https://hub.docker.com/r/eschen42/devplan/tags/):
```
make test_alpha
```

## To update README.md:
```
make doc
```

## To push changes to origin (after checking for uncommited changes):
```
make push
```

# Use cases for container setup

You can automate the set-up of the Docker container on the Docker host by running the `use_cases/devplan_bootstrap` script.
You probably don't want to run the script as root.

Set some environment variables in a file (e.g., `localhost.custom`), and then invoke the script.  For example:
```
cd use_cases
cp localhost.example localhost.custom
# edit localhost.custom to customize as desired
source devplan_bootstrap localhost.custom
# To run the container with docker-compose:
run_compose_rstudio
To run the container with docker:
run_docker_rstudio
```

Here are the environment variables used by the `use_cases/devplan_bootstrap` script:
- PASSWORD - password for rstudio-server for user `rstudio` (required)
- IMAGE - The name of the desired Docker image (default: eschen42/devplan:alpha),
  - local image-name (try `docker images`)
  - published image-name (search at https://hub.docker.com/r/eschen42/devplan/tags/)
- CONTAINER - the name of the container to be running the image (default: rstudio)
- DOCKER - command to run docker (default: docker)
   - If you are not in the group docker, set `DOCKER="sudo docker"` before sourcing `devplan_bootstrap`
- HOMEDIR - path to host folder; if it does not exist it will be created
- HOSTINTERFACE - interface where listeners will listen (default: 127.0.0.1)
  - 0.0.0.0 will listen to connections from anywhere (security risk)
  - 127.0.0.1 will listen to connection requests only from the local machine
- PREFIX - all but the last two digits of the port numbers on which listeners will listen (default:88)
- SHED_USERNAME - ID for user in the `localshed` toolshed (default: demouser)
- SHED_USEREMAIL - email for user in the `localshed` toolshed (default: demouser@example.net)
- SHED_URL - URL for the `localshed` toolshed (default: http://localhost)
  - Try to ensure that this URL will resolve in both the container and in a user's web browser
- SHED_PORT - PORT for the `localshed` toolshed (default: 8888)
  - Try to ensure that this PORT will resolve in both the container and in a user's web browser
- PLANEMO_SERVE_PORT - PORT for connecting to web server for `planemo serve` (default: 8890)
- PLANEMO_SHED_SERVE_PORT - PORT for connecting to web server for `planemo shed_serve` (default: 8889)

## `localhost.example` - Configure devplan for connections on the localhost interface

This is a configuration for bootstrapping devplan so that:
  - You run the Docker container on the same machine where you run your browser 
  - http://localhost:8587 is to connect to rstudio
    - user name: rstudio
    - password: some.password
  - http://localhost:8588 is to connect to your tool shed
    - registration name: demouser
    - registration email: demouser@example.net
  - http://localhost:8590 is to connect to `planemo serve`, which you start from the terminal tab in RStudio
  - http://localhost:8589 is to connect to `planemo shed_serve`, which you start from the terminal tab in RStudio


## `global.example` - Configure devplan for connections on your.server's global interface

This is a configuration for bootstrapping devplan so that:
  - You run the Docker container on your.server 
  - http://your.server:8987 is to connect to rstudio
    - user name: rstudio
    - password: some.password
  - http://your.server:8988 is to connect to your tool shed
    - registration name: demouser
    - registration email: demouser@example.net
  - http://your.server:8990 is to connect to `planemo serve`, which you start from the terminal tab in RStudio
  - http://your.server:8989 is to connect to `planemo shed_serve`, which you start from the terminal tab in RStudio

