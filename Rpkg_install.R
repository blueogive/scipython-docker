#!/usr/bin/env R

pkgs <- read.csv('rpkgs.csv', header=TRUE)
pkgvec <- as.vector(pkgs$Package)
library('RODBC')
withCallingHandlers(install.packages(c(pkgvec)),
                    warning=function(w) stop(w))
options(blogdown.hugo.dir='/usr/local/bin/')
blogdown::install_hugo()
tinytex::install_tinytex()
