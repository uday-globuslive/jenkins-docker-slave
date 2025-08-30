# jenkins-docker-agent

Dokcer agent integration for Jenkins is explained in this article. https://devopscube.com/docker-containers-as-build-slaves-jenkins/

Extra step for configuration in ExecStart line in /lib/systemd/system/docker.service

ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:4243 --containerd=/run/containerd/containerd.sock


Great to hear it's working now! Here's a concise summary of the issue and the fix:

---

### 🐳 **Issue Summary**

When using Docker-based Jenkins build slaves with the following Docker daemon configuration:

```ini
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:4243 --containerd=/run/containerd/containerd.sock
```

- **Jenkins builds worked** (since they connect via TCP).
- But **local Docker CLI commands (`docker ps`, `docker info`, etc.) were hanging** on the slave VM.

This happened because Docker was **only listening on the TCP socket**, and not on the default Unix socket (`/var/run/docker.sock`), which the CLI uses by default.

---

### ✅ **Fix**

Update the Docker service to listen on **both** the Unix socket and the TCP port:

```ini
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:4243 --containerd=/run/containerd/containerd.sock
```

Then reload and restart Docker:

```bash
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl restart docker
```

---

### 🎯 Result

- Jenkins can connect via TCP (`tcp://<ip>:4243`) as required.
- Local Docker CLI commands work normally via the Unix socket.

Let me know if you'd like this documented in a markdown snippet or shell script for future reference!
