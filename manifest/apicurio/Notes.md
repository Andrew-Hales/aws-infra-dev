The numbering in the `Notes.md` file is inconsistent, with some sections repeating the same number. Here's the corrected numbering:

```markdown
# Apicurio Registry Operator

## Installation

1. Create a namespace for the operator:
   ```bash
   kubectl create namespace apicurio3
   kubectl config set-context --current --namespace=apicurio3
   ```

2. Install the Operator Lifecycle Manager (OLM):
   ```bash
   curl -sL https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.32.0/install.sh | bash -s v0.32.0
   ```

Make sure you run this during step 2 and pray to god that OLM exists
3. Apply the allow-all-network.yml:
   ```bash
   kubectl apply -f allow-all-network.yml
   ```


5. Install the Apicurio Registry Operator:
   ```bash
   kubectl create -f https://operatorhub.io/install/apicurio-registry-3.yaml
   ```

6. Verify the operator installation:
   ```bash
   kubectl get csv -n operators
   ```
6.1. There may be a timing issue so keep checking until the status is `Succeeded`:
   ```bash
   kubectl get csv -n operators -w
   ```

## Custom Resource Definitions (CRDs)

- Check the CRDs introduced by the operator to start using it.


## Installing APICurio Registry

1. Create postgres password secret:
   ```bash
   kubectl create secret generic apicurio-db-secret --from-literal=password=your_password_here -n apicurio3
   ```

2. Apply the apicurio3.yml:
   ```bash
   kubectl apply -f apicurio3.yml
   ```

## Uninstallation

1. Delete the operator:
   ```bash
   kubectl delete -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.32.0/install.sh
   kubectl delete namespace olm
   kubectl delete namespace operators
   ```

2. Delete all OLM CRDs:
   ```bash
   kubectl delete crd catalogsources.operators.coreos.com \
     clusterserviceversions.operators.coreos.com \
     installplans.operators.coreos.com \
     olmconfigs.operators.coreos.com \
     operatorconditions.operators.coreos.com \
     operatorgroups.operators.coreos.com \
     operators.operators.coreos.com \
     subscriptions.operators.coreos.com
   ```

3. Delete cluster roles:
   ```bash
   kubectl delete clusterrole system:controller:operator-lifecycle-manager aggregate-olm-edit aggregate-olm-view
   kubectl delete clusterrolebinding olm-operator-binding-olm
   ```

---

## Configuration Details

- To see the configuration:
  ```bash
  kubectl explain apicurioregistry3.spec.app.storage.sql
  ```

---

# Artifact Management

- Example to upload an artifact:
  ```bash
  curl -X POST http://apicurio3-app.mint.com/apis/registry/v3/groups/my-group/artifacts \
    -H "Content-Type: application/json" \
    -H "X-Registry-ArtifactId: test-artifact" \
    --data-raw '{
      "artifactType": "AVRO",
      "name": "TestRecord",
      "content": {
        "type": "record",
        "name": "TestRecord",
        "namespace": "com.example",
        "fields": [
          {"name": "field1", "type": "string"}
        ]
      }
    }'
  ```

---

# Notes

1. **Private Endpoints for Synapse Artifacts**:
   - Use managed private endpoints in Azure Data Factory (ADF) to connect to Synapse.
   - Approve private endpoint requests in the Synapse workspace.
   - Disable public network access for Synapse.

2. **Terraform Deployment Checklist**:
   - Populate the `tfvars` file with required variables.
   - Run the `make` command in the `scripts` directory.
   - Copy images from the old ACR to the new ACR.
   - Add `dbt-ssh` and `airflow-git` secrets to the Kubernetes cluster.
   - Run the Helm install command for Airflow.
   - Manually approve all pending private endpoints.

3. **Deleting Resources in Terraform**:
   - Ensure no dependent resources (e.g., notebooks, datasets) exist before deleting Synapse or ADF linked services.

4. **Identity Types**:
   - **Azure AD Application + Service Principal**:
     - Created via `az ad app create` and `az ad sp create`.
     - Requires explicit federated credentials.
   - **User Assigned Managed Identity (UAMI)**:
     - Created via `az identity create`.
     - Azure-managed and tightly integrated with Azure resources.

---

# Airflow in AKS

1. Apply persistent volume and claim:
   ```bash
   kubectl apply -f /path/to/airflow-logs-pv.yml
   kubectl apply -f /path/to/airflow-logs-pvc.yml
   ```

2. Install Airflow using Helm:
   ```bash
   helm upgrade --install airflow apache-airflow/airflow --namespace airflow --create-namespace -f /path/to/dev-values-pg.yml
   ```

3. Set the current namespace:
   ```bash
   kubectl config set-context --current --namespace=airflow
   ```

4. Port-forward the Airflow webserver:
   ```bash
   kubectl port-forward svc/airflow-webserver 8080:8080 -n airflow
   ```

---

# Cleanup

- To delete the operator:
  ```bash
  kubectl delete namespace apicurio3
  kubectl delete namespace olm
  kubectl delete namespace operators
  ```



# External Secret Process

1.  turn the secret into a json file

```bash
    kubectl get secret ml-processing-secret-test -n airflow -o json | \
jq -r '.data | to_entries | map({(.key): (.value | @base64d)}) | add' > secret.json

```

2. Generate a multi-line secret from the file

```bash
az keyvault secret set --vault-name "mintkveusdev" --name "ml-processing-secret" --file secret.json 

```

3. Draw the rest of the owl

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: ml-processing-secret
  namespace: airflow
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: mint-secret-store
    kind: SecretStore
  target:
    name: ml-processing-secret
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        SNOWFLAKE_ACCOUNT: "{{ .account }}"
        SNOWFLAKE_DATABASE: "{{ .db }}"
        SNOWFLAKE_PASSPHRASE: "{{ .passwd }}"
        SNOWFLAKE_PRIVATE_KEY: "{{ .private_key }}"
        SNOWFLAKE_ROLE: "{{ .role }}"
        SNOWFLAKE_SCHEMA: "{{ .schema }}"
        SNOWFLAKE_USER: "{{ .usr }}"
        SNOWFLAKE_WAREHOUSE: "{{ .warehouse }}"
  data:
    - secretKey: account
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_ACCOUNT
    - secretKey: db
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_DATABASE
    - secretKey: passwd
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_PASSPHRASE
    - secretKey: private_key
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_PRIVATE_KEY
    - secretKey: role
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_ROLE
    - secretKey: schema
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_SCHEMA
    - secretKey: usr
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_USER
    - secretKey: warehouse
      remoteRef:
        key: ml-processing-secret
        property: SNOWFLAKE_WAREHOUSE
```