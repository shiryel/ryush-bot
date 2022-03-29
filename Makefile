.PHONY: test_docker
build_docker:
	docker build . -t ryush:latest
	docker run localhost/ryush:latest
