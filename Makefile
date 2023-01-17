default: image

all: image

image:
	docker pull python:3.10-slim-bullseye
	docker buildx build \
	--file Dockerfile \
	--build-arg BASE_IMAGE=python:3.10-slim-bullseye \
	--tag matthewfeickert/docker-python-template:latest \
	.

run_default:
	docker run \
		--rm \
		-ti \
		--user $(shell id -u $(USER)):$(shell id -g $(USER)) \
		--volume $(shell pwd):/work \
		matthewfeickert/docker-python-template:latest \
		/bin/bash

# Choose non-default user (aka, not uid 1000)
run_non_default:
	docker run \
		--rm \
		-ti \
		--user 2000:2000 \
		--volume $(shell pwd):/work \
		--workdir /work \
		matthewfeickert/docker-python-template:latest \
		/bin/bash

repo2docker:
	repo2docker \
	--image-name matthewfeickert/docker-python-template:binder \
	.
