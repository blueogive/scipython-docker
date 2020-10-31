# SciPython-Docker

This repo contains a `Dockerfile` to build a foundational scientific Python
[Docker](https://www.docker.com) image. Built images are hosted on
[Docker Hub](https://hub.docker.com/blueogive/scipython-docker). The
foundation of the image is the [Miniconda](https://conda.io/miniconda.html)
environment management system developed by
[Anaconda, Inc](https://www.anaconda.com/). Core packages included in the
image include:
* CPython (3.8)
* Numpy
* SciPy
* Pandas
* Cython
* Scikit-Learn
* Statsmodels
* Matplotlib
* Seaborn
* Jupyter (Notebook, Lab)
* Jupytext

Additional packages are included for:
* Documentation (Sphinx)
* Testing (pytest, coverage)
* Linting (flake8, pylint)
* Environment management (python-dotenv)
* Database connectivity (sqlalchemy, pyodbc)

In addition, it includes:
* R (4.0.3)
* RStudio-Server (1.2)
* [jupyter-rsession-proxy](https://github.com/jupyterhub/jupyter-rsession-proxy) so you can launch an RStudio session from within Jupyter Notebook
  and a collection of R packages centered around the [tidyverse](https://tidyverse.org), and literate programming.

## Usage

To instantiate an ephemeral container from the image, mount the current
directory within the container, and open a bash prompt within the `base` conda
Python environment:

```bash
docker run -it --rm -v $(pwd):/home/docker/work blueogive/scipython-docker:latest
```

You will be running as root within the container, but the image includes the
[gosu](https://github.com/tianon/gosu) utility, which allows you to conveniently execute commands as a less privileged user:

```bash
gosu 1000:100 python myscript.py
```

I borrowed much of the apparatus for enabling the launch of Jupyter Notebook/Lab server processes from the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks/), so the commands to start a Jupyter server are similar to those they suggest.

## Jupyter Notebook

```bash
docker run -it --init --rm -v $(pwd):/home/docker/work -p 8888:8888 blueogive/scipython-docker:latest gosu 1000:100 start-notebook.sh
```

Note that the `--init` argument is necessary for the Jupyter process to start correctly within the container.

## Jupyter Lab

```bash
docker run -it --init --rm -v $(pwd):/home/docker/work -p 8888:8888 -e JUPYTER_ENABLE_LAB=yes blueogive/scipython-docker:latest gosu 1000:100 start-notebook.sh
```
As the container starts, it will echo a bit of output to the console ending with statement similar to:

```
Or copy and paste one of these URLs:
        http://(<container_id> or 127.0.0.1):8888/?token=<token_value>
```
where `<container_id>` and `<token_value>` are hexadecimal strings unique to 
your instance. If the host name of the machine on which you executed the 
`docker run` command is `<host_name>`, open a web browser and put the following 
in the location bar: `http://<host_name>:8888/?token=<token_value>` to connect 
to the Jupyter Lab instance.

If you want a shell prompt as a non-root user inside the container without
starting a Jupyter server, use the command below, noting that above to start the
notebook server but change the command at the end and remove the `--init`
argument:

```bash
docker run -it --rm -v $(pwd):/home/docker/work -p 8888:8888 blueogive/scipython-docker:latest gosu 1000:100 /bin/bash
```

Pressing `CTRL-d` within the container will cause it to terminate.

## RStudio

To launch RStudio(-Server), start the container using either the Jupyter Lab or
Jupyter Notebook commands above. Then, connect to the Jupyter server using your
browser. If you started Jupyter Lab, use the menu to 'Launch Classic Notebook'.
If you started a Jupyter Notebook, skip that step. Within the classic Notebook,
click `New`, and select `RStudio`.

Contributions are welcome.
