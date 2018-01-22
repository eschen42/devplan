## # devplan: a Docker image for RStudio and Planemo development
## This image provides for Planemo development and RStudio package development (via R package 'devtools') including vignette-building capability.
## ## Step 0
##    - Choose an R version supported by bioconda and choose the corresponding version of rocker/verse, e.g.
##    ```
##        conda search r-base
##    ```
## ## Step 1
##    - Build from this Dockerfile (you must cd to the directory containing it first)
##    ```
##        docker build -t eschen42/devplan .
##    ```
## ## Step 2 
##    - Create a home directory, e.g.:
##    ```
##        mkdir ~/rstudio
##    ```
## ## Step 3
##    - Run the container with this new directory; note that the container will create
##      files in this directory with UID 1000 (which is user rstudio on the guest), e.g.:
##    ```
##        docker run --name devplan --rm -ti -p 8787:8787 -p 8790:9090 -v ~/rstudio:/home/rstudio eschen42/devplan
##    ```
##    - At this point you can use RStudio; see Step 7 below.
## ## Step 4
##    - Set up /home/rstudio/.ssh (on the guest; ~/devplan/.ssh on the host) if desired
##      and make sure that the permissions are right (see: https://superuser.com/a/215506)
## 
## ## Step 5
##    - One-time setup on the guest:
##        - Set up access to git, preferably over ssh
##        - Set up planemo in pip
##        ```
##             virtualenv ~/venv
##             . ~/venv/bin/activate
##             pip install planemo
##        ```
## ## Step 6
##    - Working on the guest:
##        - Run the following unless you have already activated the venv:
##        ```
##             . ~/venv/bin/activate
##             planemo conda_init
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
## ## Step 7
##    - On the host, browse to RStudio at http://localhost:8787
##    - Log into RStudio as user `rstudio` with password `rstudio`
## ## Step 8
##    - On the host, browse to the `planemo serve` instance at http://localhost:8790

# To view the header of this Dockerfile as markdown, run `sed -n -e '/^[^##]/,$ d; /./!d; s/^## //; p' Dockerfile`

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
RUN echo "su - rstudio" >> /init

COPY Dockerfile /Dockerfile
