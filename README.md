# SciPython-Docker

This repo contains a `Dockerfile` to build a foundational scientific Python
[Docker](https://www.docker.com) image. Built images are hosted on
[Docker Hub](https://hub.docker.com/blueogive/scipython-docker). The
foundation of the image is the [Miniconda](https://conda.io/miniconda.html)
environment management system developed by
[Anaconda, Inc](https://www.anaconda.com/). Core packages included in the
image include:
* Numpy
* SciPy
* Pandas
* Cython
* Scikit-Learn
* Statsmodels
* Matplotlib
* Seaborn

Additional packages are included for:
* Documentation (Sphinx)
* Unit testing (pytest, coverage)
* Linting (flake8)
* Environment management (python-dotenv)
* Database connectivity (sqlalchemy, pyodbc)

Contributions are welcome.
