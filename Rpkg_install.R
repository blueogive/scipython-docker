#!/usr/bin/env R

pkgs <- read.csv('rpkgs.csv', header=TRUE)
pkgvec <- as.vector(pkgs$Package)
withCallingHandlers(install.packages(c(pkgvec), Ncpus = 4L),
                    warning=function(w) stop(w))
options(blogdown.hugo.dir='/usr/local/')
blogdown::install_hugo()
tinytex::install_tinytex()
