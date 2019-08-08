# SciPython-Docker

This repo contains a `Dockerfile` to build a foundational scientific Python
[Docker](https://www.docker.com) image. Built images are hosted on
[Docker Hub](https://hub.docker.com/blueogive/scipython-docker). The
foundation of the image is the [Miniconda](https://conda.io/miniconda.html)
environment management system developed by
[Anaconda, Inc](https://www.anaconda.com/). Core packages included in the
image include:
* CPython (3.7)
* Numpy
* SciPy
* Pandas
* Cython
* Scikit-Learn
* Statsmodels
* Matplotlib
* Seaborn
* spaCy
* Jupyter (Notebook, Lab)
* Jupytext

Additional packages are included for:
* Documentation (Sphinx)
* Unit testing (pytest, coverage)
* Linting (flake8)
* Environment management (python-dotenv)
* Database connectivity (sqlalchemy, pyodbc)

In addition, it includes:
* R (3.5.1)
* RStudio-Server
* Reticulate
* [jupyter-rsession-proxy](https://github.com/jupyterhub/jupyter-server-proxy/tree/master/contrib/rstudio) so you can launch an RStudio session from within Jupyter Notebook
* and a collection of R packages

## Usage

To instantiate an ephemeral container from the image, mount the current
directory within the container, and open a bash prompt within the `base` conda
Python environment:

```bash
docker run -it --rm -v $(pwd):/home/docker/work blueogive/scipython-docker:latest
```

You will be running as root within the container, but the image includes the
[gosu](https://github.com/tianon/gosu) utility. This allows you to conveniently execute commands as other users:

```bash
gosu 1000:100 python myscript.py
```

I borrowed much of the apparatus for enabling the launch of Jupyter Notebook/Lab server processes from the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks/), so the commands to start a Jupyter server are similar to those they suggest.

## Jupyter Notebook

```bash
docker run -it --rm -v $(pwd):/home/docker/work -p 10000:8888 blueogive/scipython-docker:latest gosu 1000:100 start-notebook.sh
```

## Jupyter Lab

```bash
docker run -it --rm -v $(pwd):/home/docker/work -p 10000:8888 -e JUPYTER_ENABLE_LAB=yes blueogive/scipython-docker:latest gosu 1000:100 start-notebook.sh
```
As the container starts, it will echo a bit of output to the console ending with statement similar to:

```
Or copy and paste one of these URLs:
        http://(<container_id> or 127.0.0.1):8888/?token=<token_value>
```
where `<container_id>` and `<token_value>` are hexadecimal strings unique to your instance. If the host name of the machine on which you executed the `docker run` command is `<host_name>`, open a web browser and put the following in the location bar: `http://<host_name>:10000/?token=<token_value>` to connect to the Jupyter Lab instance.

If you want to get a shell prompt inside the container without starting a
Jupyter server, just use the command above to start the notebook server but
change the command at the end:

```bash
docker run -it --rm -v $(pwd):/home/docker/work -p 10000:8888 blueogive/scipython-docker:latest gosu 1000:100 /bin/bash
```

Pressing `CTRL-d` within the container will cause it to terminate.

Contributions are welcome.
