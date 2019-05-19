.PHONY : docker-prune docker-check docker-build docker-push

# To build an image with the latest package versions, change the value of
# CONDA_ENV_FILE to  conda-env-no-version.yml
CONDA_ENV_FILE := conda-env.yml
VCS_URL := $(shell git remote get-url --push gh)
VCS_REF := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
TAG_DATE := $(shell date -u +"%Y%m%d")

docker-prune :
	@echo Pruning Docker images/containers/networks not in use
	docker system prune

docker-check :
	@echo Computing reclaimable space consumed by Docker artifacts
	docker system df

docker-build: Dockerfile
	@docker build \
	--build-arg CONDA_ENV_FILE=$(CONDA_ENV_FILE) \
	--build-arg VCS_URL=$(VCS_URL) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--tag blueogive/scipython-docker:$(TAG_DATE) \
	--tag blueogive/scipython-docker:latest .

docker-push : docker-build
	@docker push blueogive/scipython-docker:$(TAG_DATE)
	@docker push blueogive/scipython-docker:latest
