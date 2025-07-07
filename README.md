# SciPython-Docker

This repo contains a `Dockerfile` to build a foundational scientific Python
[Docker](https://www.docker.com) image. It is intended to be the foundation of 
a development environment in a context where installing a bespoke set of 
required packages from the internet may be cumbersome or discouraged. Built 
images are hosted on 
[Docker Hub](https://hub.docker.com/blueogive/scipython-docker). 
Core packages included in the image include:

* Literate programming ([Quarto](https://quarto.org))
* R (4.5.0);
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

Create a new virtual environment that includes Jupyter:

```bash
uv init --python 3.11 --name myproject
```

Install the Python packages you need, including Jupyter Lab:

```bash
uv add jupyterlab jupyter-rsession-proxy numpy pandas matplotlib scikit-learn scipy
```

Optionally, install packages required for development:

```bash
uv add --dev ruff pytest pre-commit
```

Activate the new virtual environment:

```bash
source .venv/bin/activate
```

Verify that Node.js is installed (required for Jupyter Lab):

```bash
node --version
# This should return a version number, e.g., v18.16.0.
```

If not, install it:

```bash
bash ~/.nvm/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node && nvm cache clear
```

If you want to use `R` within Jupyter, install the `R` kernel, complete the post-install
build of Jupyter Lab, and start the service using provided script:

```bash
bash /usr/local/bin/start-jupyterlab.sh
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
