## [![DOI](https://zenodo.org/badge/118467922.svg)](https://zenodo.org/badge/latestdoi/118467922)
##
## # devplan: a Docker image for RStudio and Planemo development
##
## This image provides for Planemo development and RStudio package development:
##
##   - R 3.4.1
##   - RStudio, using this version of R.
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
## ## Step 2 - Create home directory on the host
##    - Create a home directory, e.g.:
##    ```
##        mkdir ~/rstudio
##    ```
##    - Important: Files created within ~/rstudio will be owned by the owner of ~/rstudio (and have the same group as ~/rstudio).
##      -  Make sure that you adjust ~/rstudio userid and groupid with `chown` *before* you perform step 3.
##
## ## Step 3 - Run a new container instance from the image
##    - Run the container with this new directory; note that the container will create files
##      in this directory with UID 1000 (which is user rstudio on the guest), e.g.:
##    ```
##        docker run --name devplan --rm -ti -p 8787:8787 -p 8790:9090 -p 8709:8709 -v ~/rstudio:/home/rstudio eschen42/devplan
##    ```
##    - At this point you can use RStudio; see Step 7 below.
##    - In fact, you can use the terminal interface within Rstudio (`Tools > Terminal > New Terminal`) to complete the following steps.
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
##        - Once tests are passing, run the following to serve the tool:
##        ```
##             planemo serve --host 0.0.0.0 --conda_dependency_resolution .
##        ```
##        - Because you can live-edit your tool and wrapper, you may find it more convenient
##          to have a daemon serve the current directory:
##        ```
##             planemo serve --daemon --host 0.0.0.0 --conda_dependency_resolution .
##             # or, equivalently
##             /run_planemo_shed_serve
##        ```
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
##    - To shut down the tool shed, on the guest, execute `/kill_tree`
##      - For the example above, run `/kill_tree --pid 243`
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

# To view the header of this Dockerfile as markdown, run `sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$//; p' Dockerfile`

FROM rocker/verse:3.4.1
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

# In rocker/verse, /init starts up s6 services.
#   Append to /init to log in the rstudio user after starting the s6 services.
RUN  bash -c 'mv /init /init3'
RUN  bash -c 'echo "su - rstudio" >> /init3'
COPY init /init
RUN  bash -c 'chmod +x /init'
COPY init2 /init2
RUN  bash -c 'chmod +x /init2'
COPY setup_home /setup_home
RUN  bash -c 'chmod +x /setup_home'
COPY setup_shed /setup_shed
RUN  bash -c 'chmod +x /setup_shed'
COPY run_shed /run_shed
RUN  bash -c 'chmod +x /run_shed'
COPY run_planemo_shed_serve /run_planemo_shed_serve
RUN  bash -c 'chmod +x /run_planemo_shed_serve'
COPY run_planemo_serve /run_planemo_serve
RUN  bash -c 'chmod +x /run_planemo_serve'
COPY kill_tree /kill_tree
RUN  bash -c 'chmod +x /kill_tree'

COPY Dockerfile /Dockerfile
