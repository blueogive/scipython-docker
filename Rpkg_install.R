#!/usr/bin/env R

pkgs <- read.csv('rpkgs.csv', header=TRUE)
pkgvec <- as.vector(pkgs$Package)
withCallingHandlers(install.packages(c(pkgvec)),
                    warning=function(w) stop(w))
remotes::install_github("nx10/httpgd")
tinytex::install_tinytex()
# The next command requires Jupyter to be installed an on the path.
IRkernel::installspec()
