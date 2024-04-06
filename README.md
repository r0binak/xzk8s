# xzk8s
[![Docker Pulls xzk8s](https://img.shields.io/docker/pulls/r0binak/xzk8s?logo=docker)](https://hub.docker.com/r/r0binak/xzk8s)

Dockerfile and Kubernetes manifests for reproduce CVE-2024-3094

# Build image

We use the debian version of the vulnerable xz utils as the base image. We also need to patch the library. The patched version of the liblzma library is taken from the [xzbot repository](https://github.com/amlweems/xzbot/).

```dockerfile
FROM debian:experimental-20240311@sha256:16cc2b09c44d991d36f63153f13a7c98fb7da6bd2ba9d7cc0f48baacb7484970
# use debian with a vulnerable version of xz utils as the base image
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:root123' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22

COPY liblzma.so.5.6.0.patch /root/
# in order to exploit the vulnerability you must use a patched library because 
# the exploit author originally hardcoded his public key
# in the patched library this key has been swapped out

ENV LD_PRELOAD=/root/liblzma.so.5.6.0.patch

# load the patched library via LD_PRELOAD

CMD ["/usr/sbin/sshd", "-D"]
```

# Exploit demo

First, we must deploy a simple Pod, with the image assembled in the previous step:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cve-2024-3094
  labels:
    app: cve-2024-3094
spec:
  containers:
  - name: cve-2024-3094
    image: r0binak/xzk8s:v1
    ports:
    - containerPort: 22
```

Then, redirect the ports:

```bash
kubectl port-forward backdoor-cve-2024-3094 2222:22
```

Let's use the [xzbot](https://github.com/amlweems/xzbot/) exploit:

![](./assets/xzbot.png)

Finally, let's go inside the container and check the exploit results:

![](./assets/results.png)

# References

- https://github.com/amlweems/xzbot/
- https://www.openwall.com/lists/oss-security/2024/03/29/4
- https://gist.github.com/smx-smx/a6112d54777845d389bd7126d6e9f504
- https://gist.github.com/q3k/af3d93b6a1f399de28fe194add452d01
- https://gist.github.com/keeganryan/a6c22e1045e67c17e88a606dfdf95ae4
