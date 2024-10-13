# SciPython-Docker

This repo contains a `Dockerfile` to build a foundational scientific Python
[Docker](https://www.docker.com) image. It is intended to be the foundation of 
a development environment in a context where installing a bespoke set of 
required packages from the internet may be cumbersome or discouraged. Built 
images are hosted on 
[Docker Hub](https://hub.docker.com/blueogive/scipython-docker). The
foundation of the image is the 
[Mambaforge](https://github.com/conda-forge/miniforge#mambaforge)
environment management system developed by the Conda-Forge community. 
Core packages included in the image include:
* CPython (3.12)

Additional packages are included for:
* Documentation (Sphinx)
* Testing (pytest, coverage)
* Linting (flake8, pylint)
* Environment management (python-dotenv)
* Database connectivity (sqlalchemy, pyodbc, pymssql)
* Literate programming ([Quarto](https://quarto.org))

In addition, it includes:
* R (4.4.1);
* RStudio-Server;
* [jupyter-rsession-proxy](https://github.com/jupyterhub/jupyter-rsession-proxy),
  so you can launch an RStudio session from within Jupyter Notebook/Lab,
  and a collection of R packages centered around the 
  [tidyverse](https://tidyverse.org), and literate programming;


## Usage

To instantiate an ephemeral container from the image, mount the current
directory within the container, and open a bash prompt within the `base` conda
Python environment:

```bash
docker run -it --rm -v $(pwd):/home/docker/work blueogive/scipython-docker:latest
```

By default, you will be running as the (unprivileged) `docker` user within the 
container.

## Typical Usage

Instantiate a container from the image:

```bash
docker run -d --name <container_name> -v $(pwd):/home/docker/work -p 8888:8888 --restart unless-stopped blueogive/scipython-docker:latest /bin/sleep infinity
```

replacing `<container_name>` with the name you wish to assign to your container.

At this point, you will have a Bash shell with the `base` mamba/conda Python 
virtual environment will be active. You can use the remote development 
capabilities of VSCode to connect to the container and begin working.

Alternatively, you may wish to use Jupyter Lab and/or RStudio within the
container. In that case, you can use the `entrypoint` argument to have the
container set up a starter environment:

```bash
docker run -d --name <container_name> -v $(pwd):/home/docker/work -p 8888:8888 --restart unless-stopped --entrypoint /usr/local/bin/start-jupyterlab.sh blueogive/scipython-docker:latest
```

As the container starts, it will require 2--3 minutes to build the environment.
The process should end when the Jupyter Lab process starts and echoes a URL to
the terminal. Open the URL in your browser to connect to the Jupyter Lab process
in the container. You can start RStudio by clicking the launcher on the Jupyter
Lab home screen.

Alternatively, if your requirements are more exacting, you can complete some of
the same steps taken by the `entrypoint` script manually and modify them to fit
your needs. Open a shell within the container:

```bash
docker exec -it <container_name> /bin/bash
```

Create a new conda/mamber virtual environment that includes Jupyter (because the
`base` virtual environment does not):

```bash
mamba env create -f ~/miniforge3/examples/conda-env-minimal.yml
```

Activate the new virtual environment:

```bash
mamba activate minimal
```

If you want to use `R` within Jupyter, install the `R` kernel:

```bash
Rscript -e "IRkernel::installspec()"
```

Complete the post-install build of Jupyter Lab and start the service:

```bash
jupyter lab build
jupyter lab --no-browser --ip 0.0.0.0 --notebook-dir=~/work
```

As Jupyter Lab starts, it will echo a bit of output to the console ending with statement similar to:

```
Or copy and paste one of these URLs:
        http://(<container_id> or 127.0.0.1):8888/?token=<token_value>
```
where `<container_id>` and `<token_value>` are hexadecimal strings unique to
your instance. On your host, open your preferred browser and point it to
`http://localhost:8888/?token=<token_value>` to connect to the Jupyter Lab
instance.

Contributions are welcome.
