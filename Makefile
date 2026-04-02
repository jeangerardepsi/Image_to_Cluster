all: build cluster deploy

build:
	packer init build.pkr.hcl
	packer build build.pkr.hcl

cluster:
	k3d image import my-custom-nginx:latest -c lab

deploy:
	ansible-playbook deploy.yml -e "ansible_python_interpreter=$(shell which python3)"
