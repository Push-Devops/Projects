# EKS Pod to S3 Access Troubleshooting Guide (OSI Model Approach)

This guide uses the **OSI (Open Systems Interconnection) Model** to systematically troubleshoot access issues from an EKS Pod to an S3 Bucket.

## Prerequisites
- `kubectl` configured with cluster access.
- AWS CLI installed locally.
- A "debug pod" with `curl`, `nslookup`, `aws-cli`, and `jwt-cli` (optional but helpful) installed.

### Quick Debug Pod Creation
If you don't have a pod to test from, run this:
```bash
kubectl run debug-pod --rm -it --image=amazon/aws-cli --command -- /bin/bash
# Once inside, you can run the commands listed below.
```

---

## Layer 1: Physical Layer (Infrastructure Status)
**Goal:** Verify the underlying compute resources are functional.

1.  **Check Node Status**
    Ensure the node running your pod is `Ready`.
    ```bash
    kubectl get nodes -o wide
    ```
    *Look for `Status: Ready`.*

2.  **Check Pod Status**
    Ensure the pod is actually running.
    ```bash
    kubectl get pods -o wide
    ```

---

## Layer 2: Data Link Layer (CNI & Network Interfaces)
**Goal:** Verify the Pod has a valid IP and network interface.

1.  **Check Pod IP Assignment**
    Verify the pod has an IP address assigned.
    ```bash
    kubectl describe pod <pod-name> | grep IP
    ```

2.  **Verify AWS ENI (Elastic Network Interface)**
    Check `aws-node` logs if IPs aren't assigning.
    ```bash
    kubectl logs -n kube-system -l k8s-app=aws-node
    ```

---

## Layer 3: Network Layer (Routing & DNS)
**Goal:** Verify the Pod can resolve names and route packets to S3.

1.  **Check DNS Resolution**
    Can the pod resolve the S3 endpoint?
    ```bash
    # Inside the pod
    nslookup s3.amazonaws.com
    # OR for specific region
    nslookup s3.us-east-1.amazonaws.com
    ```

2.  **Check Routing Table**
    Does the route exist?
    ```bash
    ip route show
    ```

---

## Layer 4: Transport Layer (Connectivity & Firewalls)
**Goal:** Verify TCP connectivity (Port 443).

1.  **Test Port 443 Connectivity**
    Confirm Security Groups and NACLs allow traffic.
    ```bash
    # Inside the pod
    curl -v --telnet s3.amazonaws.com 443
    # OR using nc
    nc -zv s3.us-east-1.amazonaws.com 443
    ```
    *If this fails (Timeout), check Security Groups (Outbound 443) and VPC Endpoints.*

---

## Layer 7: Application Layer (HTTP & AWS API)
**Goal:** Verify the application can make the request.

1.  **Run AWS CLI List Command**
    ```bash
    aws s3 ls s3://<your-bucket-name> --region <region>
    ```

2.  **Interpret the Response Code:**
    *   **200 OK:** Success.
    *   **403 Forbidden:** **This is an Identity/Auth issue (see below).**
    *   **404 Not Found:** Bucket does not exist.
    *   **Timeout:** Layer 3/4 issue.

---

## "Layer 8": Identity & Authentication (IRSA Deep Dive)
**Goal:** Verify IAM Roles for Service Accounts (IRSA) configuration. This is the **most critical section** for 403 errors.

### Phase 1: Kubernetes Side Verification

1.  **Verify Service Account Association**
    Ensure the Pod spec refers to the correct Service Account.
    ```bash
    kubectl get pod <pod-name> -o jsonpath='{.spec.serviceAccountName}'
    ```

2.  **Verify Service Account Annotation**
    The Service Account must have the IAM Role ARN annotation.
    ```bash
    kubectl describe sa <service-account-name>
    # Check for Annotation:
    # eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/YOUR_IAM_ROLE
    ```

3.  **Verify Mutating Webhook Injection**
    When the pod starts, the EKS Pod Identity Webhook should inject environment variables and a token volume.
    ```bash
    # Check for AWS Env Vars
    kubectl exec <pod-name> -- env | grep AWS
    # Expected Output:
    # AWS_ROLE_ARN=arn:aws:iam::...
    # AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
    ```
    *If these are missing, the pod was likely created BEFORE the Service Account was annotated, or the webhook is failing.*

4.  **Inspect the Projected Volume Token**
    The token file must exist and be readable.
    ```bash
    kubectl exec <pod-name> -- cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token
    ```

5.  **Decode the Token (Crucial)**
    Copy the token string from step 4 and decode it (use `jwt.io` or `jq` if available).
    ```bash
    # Verify the 'iss' (Issuer) matches your EKS Cluster OIDC URL
    # Verify the 'sub' (Subject) matches: system:serviceaccount:<namespace>:<service-account>
    # Verify 'aud' (Audience) is "sts.amazonaws.com"
    ```

### Phase 2: AWS IAM Side Verification

6.  **Verify OIDC Provider in IAM**
    Get your Cluster's OIDC Issuer URL:
    ```bash
    aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text
    # Example: https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE12345...
    ```
    Check if this provider exists in IAM:
    ```bash
    aws iam list-open-id-connect-providers
    ```
    *The ARN from the list command must contain the ID from your cluster's OIDC URL.*

7.  **Verify IAM Role Trust Policy (The Exact Match)**
    Get the Trust Policy:
    ```bash
    aws iam get-role --role-name <role-name> --query "Role.AssumeRolePolicyDocument"
    ```
    **Critical Check:** The `Condition` block must match **exactly**.
    ```json
    "Condition": {
        "StringEquals": {
            "oidc.eks.<region>.amazonaws.com/id/<CLUSTER_ID>:sub": "system:serviceaccount:<NAMESPACE>:<SERVICE_ACCOUNT_NAME>",
            "oidc.eks.<region>.amazonaws.com/id/<CLUSTER_ID>:aud": "sts.amazonaws.com"
        }
    }
    ```
    *Common Error: Mismatched Namespace or Service Account name in the `sub` field.*

8.  **Verify IAM Permissions**
    Does the role actually have S3 access?
    ```bash
    aws iam get-role-policy --role-name <role-name> --policy-name <policy-name>
    # OR for attached policies
    aws iam list-attached-role-policies --role-name <role-name>
    ```

### Phase 3: End-to-End Simulation

9.  **Manual Assume Role Test (Inside Pod)**
    Try to manually assume the role using the token file. This isolates whether the token is valid for the role.
    ```bash
    # Inside the pod
    aws sts assume-role-with-web-identity \
      --role-arn $AWS_ROLE_ARN \
      --role-session-name test-session \
      --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE \
      --duration-seconds 3600
    ```
    *   **Success:** Returns AccessKey, SecretKey, SessionToken. (Issue is likely in your app code or SDK version).
    *   **Failure (AccessDenied):** Trust relationship (Step 7) is wrong.
    *   **Failure (InvalidIdentityToken):** OIDC provider missing (Step 6) or token issuer mismatch (Step 5).

10. **Policy Simulation**
    If Step 9 works but S3 still denies:
    ```bash
    aws iam simulate-principal-policy \
        --policy-source-arn <your-role-arn> \
        --action-names s3:ListBucket s3:GetObject \
        --resource-arns arn:aws:s3:::<your-bucket>
    ```

---

## Summary Troubleshooting Flowchart

1.  **Layer 1-4 OK?** (Node Ready, DNS resolves, TCP 443 connects) -> **Go to Step 2.**
2.  **Env Vars OK?** (`AWS_ROLE_ARN`, `AWS_WEB_IDENTITY_TOKEN_FILE` present in pod) -> **Go to Step 3.**
3.  **Trust Policy OK?** (`sub` matches `system:serviceaccount:ns:sa`) -> **Go to Step 4.**
4.  **Manual Assume Role OK?** (`aws sts assume-role...` works) -> **Go to Step 5.**
5.  **S3 Policy/IAM Policy OK?** (Check explicit Denies or missing Actions) -> **Fix Policy.**
