.PHONY : docker-prune docker-check docker-build docker-push

# To build an image with the latest package versions, change the value of
# CONDA_ENV_FILE to  conda-env-no-version.yml
# CONDA_ENV_FILE := conda-env.yml
# CONDA_ENV_FILE := conda-env-no-version.yml
VCS_URL := $(shell git remote get-url --push gh)
VCS_REF := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
TAG_DATE := $(shell date -u +"%Y%m%d")
DOCKER_HUB_USER := blueogive
DOCKER_IMG_NAME := scipython-docker
# DO (Not) Use BuildKit
export DOCKER_BUILDKIT := 1

docker-prune :
	@echo Pruning Docker images/containers/networks not in use
	docker system prune

docker-check :
	@echo Computing reclaimable space consumed by Docker artifacts
	docker system df

docker-login:
	@pass hub.docker.com/$(DOCKER_HUB_USER) | docker login -u $(DOCKER_HUB_USER) --password-stdin

docker-debug:
	@echo "Debugging Docker build with BuildKit enabled"
	@./debug-build.sh

docker-build: Dockerfile docker-login
	@docker build \
	--progress=auto \
	--debug \
	--iidfile .docker-iid.txt \
	--build-arg VCS_URL=$(VCS_URL) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--tag $(DOCKER_HUB_USER)/$(DOCKER_IMG_NAME):$(TAG_DATE) \
	--tag $(DOCKER_HUB_USER)/$(DOCKER_IMG_NAME):latest .

docker-push : docker-build
	@docker push $(DOCKER_HUB_USER)/$(DOCKER_IMG_NAME):$(TAG_DATE)
	@docker push $(DOCKER_HUB_USER)/$(DOCKER_IMG_NAME):latest
