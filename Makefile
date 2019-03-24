.PHONY : docker-clean docker-prune docker-check docker-build

VCS_URL := $(shell git remote get-url --push gh)
VCS_REF := $(shell git rev-parse --short HEAD)
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

docker-clean :
	@echo Removing dangling/untagged images
	docker images -q --filter dangling=true | xargs docker rmi --force

docker-prune :
	@echo Pruning Docker images/containers not in use
	docker system prune -a

docker-check :
	@echo Computing reclaimable space consumed by Docker artifacts
	docker system df

docker-build: Dockerfile
	@docker build \
	--build-arg VCS_URL=$(VCS_URL) \
	--build-arg VCS_REF=$(VCS_REF) \
	--build-arg BUILD_DATE=$(BUILD_DATE) \
	--tag blueogive/scipython-docker:latest .
