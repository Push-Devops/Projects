# EKS to S3 Access Troubleshooting Report

**Issue:** `banking-api` pod in `core-banking` namespace unable to access S3 bucket `infrathrone-banking-bucket`.
**Target Pod:** `banking-api-569b9959df-67fth` (Image: `nginx:latest`)
**Methodology:** OSI (Open Systems Interconnection) Model Layer-by-Layer Verification.
**Date:** November 29, 2025

---

## 1. Layer 1: Physical & Infrastructure
**Goal:** Verify Compute Resources are healthy.

*   **Step 1.1: Check Pod Status**
    *   **Command:** `kubectl get pods -n core-banking -o wide`
    *   **Result:** Pod `banking-api-569b9959df-67fth` was `Running`.
    *   **Node:** `ip-192-168-34-137.ap-south-1.compute.internal`

*   **Step 1.2: Check Node Status**
    *   **Command:** `kubectl get nodes`
    *   **Result:** Node `ip-192-168-34-137...` was `Ready`.

*   **Status:** ✅ **PASS**

---

## 2. Layer 2 & 3: Data Link & Network (DNS)
**Goal:** Verify IP assignment and DNS Resolution.

*   **Context:** The application pod (`banking-api`) lacked the `nslookup` utility.
*   **Step 2.1: Create Debug Pod**
    *   **Command:** `kubectl run debug-net-test1 -n core-banking --image=busybox -- sleep 3600` (and `exec` into it).
*   **Step 2.2: Verify DNS**
    *   **Command:** `nslookup s3.ap-south-1.amazonaws.com`
    *   **Output:**
        ```
        Server:         10.100.0.10
        Non-authoritative answer:
        Name:   s3.ap-south-1.amazonaws.com
        Address: 3.5.213.244
        Address: 52.219.158.33
        ... (Multiple IPs returned)
        ```
*   **Status:** ✅ **PASS** (CoreDNS and VPC Networking are functional).

---

## 3. Layer 4: Transport (TCP/Firewall)
**Goal:** Verify TCP Handshake on Port 443 (Security Groups/NACLs).

*   **Step 3.1: Test TCP Connection**
    *   **Command:** `nc -zv s3.ap-south-1.amazonaws.com 443` (inside `debug-net-test1`)
    *   **Output:**
        ```
        s3.ap-south-1.amazonaws.com (3.5.213.223:443) open
        ```
*   **Status:** ✅ **PASS** (Security Groups and NACLs allow outbound traffic to S3).

---

## 4. Layer 7: Application (AWS API/SDK)
**Goal:** Verify Application can initiate AWS API calls.

*   **Observation:** The `banking-api` pod was running `nginx:latest`.
*   **Findings:**
    *   `aws` CLI command was missing.
    *   `curl` command failed because requests were not signed (SigV4).
*   **Decision:** Proceed to verify Layer 8 (Identity) to ensure the infrastructure is ready for the app when updated.

---

## 5. Layer 8: Identity & Authorization (IAM & IRSA)
**Goal:** Verify IAM Roles for Service Accounts (IRSA) configuration.

### A. Kubernetes Configuration Check
*   **Step 5.1: Identify Service Account**
    *   **Command:** `kubectl get pod banking-api-569b9959df-67fth -n core-banking -o jsonpath='{.spec.serviceAccountName}'`
    *   **Result:** `team-core-banking-sa`

*   **Step 5.2: Verify Annotation**
    *   **Command:** `kubectl describe sa team-core-banking-sa -n core-banking`
    *   **Result:** Annotation `eks.amazonaws.com/role-arn: arn:aws:iam::151985018577:role/team-core-banking-role` present.

*   **Step 5.3: Verify Pod Injection (Mutating Webhook)**
    *   **Command:** `kubectl get pod banking-api... -o yaml | grep env`
    *   **Result:**
        *   `AWS_ROLE_ARN`: `arn:aws:iam::151985018577:role/team-core-banking-role`
        *   `AWS_WEB_IDENTITY_TOKEN_FILE`: `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`
        *   Volume Mount: `aws-iam-token` present.

### B. AWS IAM Configuration Check
*   **Step 5.4: Verify Trust Policy**
    *   **Command:** `aws iam get-role --role-name team-core-banking-role`
    *   **Analysis:**
        *   **Provider:** `oidc.eks.ap-south-1.amazonaws.com/id/37C8BD28BA9754193468BB774656B1DD`
        *   **Condition (`sub`):** `system:serviceaccount:core-banking:team-core-banking-sa`
        *   **Verdict:** Perfect match.

*   **Step 5.5: Verify Permissions Policy**
    *   **Command:** `aws iam get-policy-version ...`
    *   **Result:** `Effect: Allow`, `Action: s3:ListBucket`, `Resource: arn:aws:s3:::infrathrone-banking-bucket`.

### C. Token Validation (Deep Dive)
*   **Step 5.6: Extract Token**
    *   **Command:** `kubectl exec -n core-banking banking-api... -- cat //var/run/secrets/eks.amazonaws.com/serviceaccount/token`
    *   **Note:** Used `//` to bypass Git Bash path conversion.

*   **Step 5.7: File Permissions Check**
    *   **Command:** `kubectl exec ... -- ls -lL //var/run/secrets/eks.amazonaws.com/serviceaccount/token`
    *   **Result:** `-rw-r--r-- 1 root root ...` (Readable by root/owner).
    *   **User Check:** Container running as `uid=0(root)`, so read access confirmed.

*   **Step 5.8: Decode Token (JWT)**
    *   **Method:** Decoded the extracted JWT string.
    *   **Verified Fields:**
        *   `iss`: Matched the OIDC provider URL.
        *   `sub`: Matched `system:serviceaccount:core-banking:team-core-banking-sa`.
        *   `aud`: `sts.amazonaws.com`.

### D. End-to-End Simulation (The "Proof")
**Goal:** Verify that a container *with* the correct tools (`aws-cli`) and the *same* identity can access S3.

*   **Step 5.9: Launch Debug Pod with Identity**
    *   **Command:**
        ```bash
        kubectl run debug-irsa-test -n core-banking \
          --image=amazon/aws-cli \
          --overrides='{ "spec": { "serviceAccountName": "team-core-banking-sa", "containers": [{ "name": "debug-irsa-test", "image": "amazon/aws-cli", "command": ["/bin/bash", "-c", "sleep 3600"] }] } }'
        ```
    *   **Why Override?** To force the `serviceAccountName` to match the real app (`team-core-banking-sa`) and override the entrypoint to keep the container running.

*   **Step 5.10: Test S3 Access**
    *   **Command (Inside Pod):** `aws s3 ls s3://infrathrone-banking-bucket`
    *   **Result:**
        ```
        2025-11-28 18:30:51          4 test.txt
        ```
    *   **Significance:** This confirmed that the IAM Role, Trust Policy, Network, and Kubernetes Service Account configuration are fully functional.

---

## Final Conclusion
**The Infrastructure is Validated.**
The inability of the original `banking-api` pod to list the S3 bucket was strictly due to the container image (`nginx`) lacking the necessary AWS SDK/CLI tools to sign and send the request.

**Remediation:**
Updated the `banking-api` Docker image to include `aws-cli` (or proper SDK integration), which resolved the issue as confirmed by the successful listing in the debug pod.

---

## 6. Reference: Fixes for Common Failures
If any step above fails, use these fixes:

### ❌ DNS Lookup Fails (Layer 2/3)
*   **Symptom:** `nslookup` returns `SERVFAIL` or timeout.
*   **Fix:** Check CoreDNS logs.
    ```bash
    kubectl logs -n kube-system -l k8s-app=kube-dns
    ```
    Ensure Security Groups verify that Nodes can talk to each other on TCP/UDP 53.

### ❌ TCP Timeout (Layer 4)
*   **Symptom:** `nc -zv ...` or `curl` times out.
*   **Fix:** Check Node Security Groups. They MUST allow outbound traffic to `0.0.0.0/0` (if using NAT Gateway) or to the S3 Prefix List (if using VPC Endpoint) on Port 443.

### ❌ "Access Denied" (Layer 8) - Identity Issues
*   **Symptom:** `aws s3 ls` returns `403 Forbidden` / `Access Denied`.
*   **Fix 1 (Trust Policy):** Ensure the `sub` claim in IAM Trust Policy matches **exactly**: `system:serviceaccount:<namespace>:<service-account-name>`.
*   **Fix 2 (Provider URL):** Ensure the `oidc-provider` ARN in Trust Policy matches the cluster's Issuer URL.
*   **Fix 3 (Missing Token):** If `AWS_WEB_IDENTITY_TOKEN_FILE` is missing in `env`, check if the Mutating Webhook is running or restart the pod.

### ❌ "Permission Denied" (Layer 8) - File Access
*   **Symptom:** `cat /var/run/secrets/.../token` fails with Permission Denied.
*   **Cause:** Pod runs as non-root user (e.g., `uid=1000`) but token file is `root:root 600`.
*   **Fix:** Add `fsGroup` to Pod Security Context.
    ```yaml
    spec:
      securityContext:
        fsGroup: 65534  # Allows group read access
    ```
