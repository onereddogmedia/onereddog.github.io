SHELL:=/bin/bash

build::
	@echo "Building"; \
	hugo --minify --baseURL "https://www.onereddog.com.au"

server:
	@echo "Debug server"; \
	hugo server

clean:
	rm -rf ./public
