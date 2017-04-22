ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
AM_BRANCH := "qa/jisc"
SS_BRANCH := "qa/jisc"

build: build-images

build-images: build-image-dashboard build-image-mcpserver build-image-mcpclient build-image-storage-service

build-image-dashboard:
	docker build --rm --pull \
		--tag rdss-archivematica-dashboard:latest \
		-f $(ROOT_DIR)/src/archivematica/src/dashboard.Dockerfile \
			$(ROOT_DIR)/src/archivematica/src/

build-image-mcpserver:
	docker build --rm --pull \
		--tag rdss-archivematica-mcpserver:latest \
		-f $(ROOT_DIR)/src/archivematica/src/MCPServer.Dockerfile \
			$(ROOT_DIR)/src/archivematica/src/

build-image-mcpclient:
	docker build --rm --pull \
		--tag rdss-archivematica-mcpclient:latest \
		-f $(ROOT_DIR)/src/archivematica/src/MCPClient.Dockerfile \
			$(ROOT_DIR)/src/archivematica/src/

build-image-storage-service:
	docker build --rm --pull \
		--tag rdss-archivematica-storage-service:latest \
		-f $(ROOT_DIR)/src/archivematica-storage-service/Dockerfile \
			$(ROOT_DIR)/src/archivematica-storage-service/

clone:
	git clone --branch $(AM_BRANCH) git@github.com:JiscRDSS/archivematica.git $(ROOT_DIR)/src/archivematica
	git clone --branch $(SS_BRANCH) git@github.com:JiscRDSS/archivematica-storage-service.git $(ROOT_DIR)/src/archivematica-storage-service
	git clone --depth 1 --recursive --branch master https://github.com/artefactual/archivematica-sampledata.git $(ROOT_DIR)/src/archivematica-sampledata
