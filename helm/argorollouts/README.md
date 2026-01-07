# Argo Rollouts Helloworld Example

This directory contains a full example for deploying a canary rollout using Argo Rollouts.

## Files
- `install-argo-rollouts.sh`: Script to install Argo Rollouts via Helm.
- `helloworld-rollout.yaml`: Example Rollout and Service manifest.

## Usage

1. **Install Argo Rollouts:**
   ```sh
   ./install-argo-rollouts.sh
   ```

2. **Apply the Helloworld Rollout:**
   ```sh
   kubectl apply -f helloworld-rollout.yaml
   ```

3. **Monitor the Rollout:**
   ```sh
   kubectl argo rollouts get rollout helloworld-rollout -n argo-rollouts
   ```

4. **Access the Service:**
   - Port-forward to test:
     ```sh
     kubectl port-forward svc/helloworld-service 8080:80 -n argo-rollouts
     curl http://localhost:8080
     ```

5. **Promote the Rollout (if paused):**
   ```sh
   kubectl argo rollouts promote helloworld-rollout -n argo-rollouts
   ```

## Blue-Green Example

1. **Apply the Blue-Green Rollout:**
   ```sh
   kubectl apply -f helloworld-bluegreen-rollout.yaml
   ```

2. **Monitor the Blue-Green Rollout:**
   ```sh
   kubectl argo rollouts get rollout helloworld-bluegreen -n argo-rollouts
   ```

3. **Promote the Blue-Green Rollout:**
   ```sh
   kubectl argo rollouts promote helloworld-bluegreen -n argo-rollouts
   ```

4. **Access the Active and Preview Services:**
   - Port-forward to test active:
     ```sh
     kubectl port-forward svc/helloworld-bluegreen-active 8081:80 -n argo-rollouts
     curl http://localhost:8081
     ```
   - Port-forward to test preview:
     ```sh
     kubectl port-forward svc/helloworld-bluegreen-preview 8082:80 -n argo-rollouts
     curl http://localhost:8082
     ```

## Reference
- [Argo Rollouts Documentation](https://argoproj.github.io/argo-rollouts/)
