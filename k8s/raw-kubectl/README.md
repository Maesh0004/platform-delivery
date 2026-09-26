# v1 - Raw kubectl Manifests (legacy)

These are the original, hand-written Kubernetes manifests used by the **first
version** of this project (see the `v1-raw-kubectl` git tag).

They were applied directly with `kubectl apply` from the Jenkins pipeline, and the
application image was rolled out afterwards with `kubectl set image`.

**They are kept for reference only and are no longer used by the pipeline.**

The active deployment path is now the Helm chart in `../../helm/ride-connect/`.

## Why the project moved to Helm

- Environment values (namespace, image tag, ingress host, storageClass, replicas)
  were hardcoded in every file - adding an environment meant copying and
  hand-editing manifests.
- `kubectl apply` followed by `kubectl set image` is a two-phase, non-atomic
  deploy with no automatic rollback.
- Editing the ConfigMap did not restart the application pods (no checksum
  annotation), so configuration changes were silently ignored by running pods.

See `README.md` (Evolution section) for the full v1 -> v2 migration story.
