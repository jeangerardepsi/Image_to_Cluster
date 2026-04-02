 `README.md` :

```markdown
# 🏗️ Atelier : From Image to Cluster (Packer + K3d + Ansible)

Ce projet démontre une chaîne DevOps complète permettant de construire une image immuable, de la provisionner dans un cluster Kubernetes local et d'orchestrer son déploiement.

---

## 🚀 Séquence 1 : Build de l'image (Packer)
Nous utilisons Packer avec le plugin Docker pour créer une image Nginx personnalisée qui contient notre fichier `index.html`.

**Fichier `build.pkr.hcl` :**
```hcl
packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "[github.com/hashicorp/docker](https://github.com/hashicorp/docker)"
    }
  }
}

source "docker" "nginx" {
  image  = "nginx:latest"
  commit = true
}

build {
  name = "my-custom-nginx-build"
  sources = ["source.docker.nginx"]

  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  post-processor "docker-tag" {
    repository = "my-custom-nginx"
    tags       = ["latest"]
  }
}
```

---

## 🚢 Séquence 2 : Préparation du Cluster (K3d)
Le cluster est créé avec K3d, en mappant le port 8080 de l'hôte vers le port 80 du LoadBalancer Kubernetes.

```bash
# Création du cluster
k3d cluster create lab --port "8080:80@loadbalancer"

# Import de l'image buildée par Packer
k3d image import my-custom-nginx:latest -c lab
```

---

## 🚀 Séquence 3 : Déploiement Applicatif (Ansible)
Le déploiement est orchestré par Ansible pour garantir l'état souhaité des ressources (Deployment et Service).

**Fichier `deploy.yml` :**
```yaml
---
- name: Deploiement de l'image custom sur K3d
  hosts: localhost
  connection: local
  tasks:
    - name: Creer un Deployment Nginx
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: custom-nginx-deploy
            namespace: default
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: my-nginx
            template:
              metadata:
                labels:
                  app: my-nginx
              spec:
                containers:
                - name: nginx-container
                  image: my-custom-nginx:latest
                  imagePullPolicy: Never # Force l'usage de l'image locale
                  ports:
                  - containerPort: 80

    - name: Creer un Service LoadBalancer
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: custom-nginx-service
            namespace: default
          spec:
            selector:
              app: my-nginx
            ports:
              - protocol: TCP
                port: 80
                targetPort: 80
            type: LoadBalancer
```

---

## 🤖 Séquence 4 : Automatisation (Makefile)
Pour simplifier l'utilisation, un **Makefile** permet de lancer toutes les étapes en une commande.

```makefile
all: build cluster deploy

build:
	packer init build.pkr.hcl
	packer build build.pkr.hcl

cluster:
	k3d image import my-custom-nginx:latest -c lab

deploy:
	ansible-playbook deploy.yml -e "ansible_python_interpreter=$(shell which python3)"
```

**Usage :** Tapez simplement `make all` pour reconstruire et redéployer l'intégralité de la solution.

---

## ✅ Vérification finale
```bash
kubectl get all
```
