## [![DOI](https://zenodo.org/badge/118467922.svg)](https://zenodo.org/badge/latestdoi/118467922)
##
## # devplan: a Docker image for RStudio and Planemo development
##
## This image provides for Planemo development and RStudio package development (via R package 'devtools') including vignette-building capability.
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
##        docker run --name devplan --rm -ti -p 8787:8787 -p 8790:9090 -v ~/rstudio:/home/rstudio eschen42/devplan
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
##
## ## Step 7 - Running RStudio
##    - On the host, browse to RStudio at http://localhost:8787
##    - Log into RStudio as user `rstudio` with password `rstudio`
##
## ## Step 8 - Browsing results for `planemo serve`
##    - On the host, browse to the `planemo serve` instance at http://localhost:8790
##

# To view the header of this Dockerfile as markdown, run `sed -n -e '/^##/ !d; /./!d; s/^## //; s/^##$//; p' Dockerfile`

FROM rocker/verse:3.4.1
MAINTAINER Arthur C. Eschenlauer, esch0041@umn.edu

RUN apt-get update

# texlive-common includes both texlive-science and texlive-latex-extra
RUN apt-get install -y texlive-common
# Set up some utilities that I don't want to be without
RUN apt-get -y install bzip2 curl wget vim-tiny 
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

COPY Dockerfile /Dockerfile
