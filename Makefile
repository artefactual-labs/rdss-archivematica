ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

build: build-images

build-images: build-image-dashboard build-image-mcpserver build-image-mcpclient

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

clone:
	git clone git@github.com:JiscRDSS/archivematica.git $(ROOT_DIR)/src/archivematica
	git clone git@github.com:JiscRDSS/archivematica-storage-service.git $(ROOT_DIR)/src/archivematica-storage-service.git
