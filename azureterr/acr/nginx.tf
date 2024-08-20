/*
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
#  version    = "1.41.3"
  create_namespace = true
  depends_on = [azurerm_kubernetes_cluster.example]
}

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "3.35.4"

  values = [file("values/argocd.yaml")]
}

resource "null_resource" "create_pod" {
  provisioner "local-exec" {
    command = <<EOT
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: newpod
spec:
  containers:
  - name: newpod
    image: nginx:latest
EOF
    EOT
  }
}
*/
/*
resource "kubernetes_manifest" "storageclass_azuredisk_premium_retain" {
  manifest = {
    "allowVolumeExpansion" = true
    "apiVersion" = "storage.k8s.io/v1"
    "kind" = "StorageClass"
    "metadata" = {
      "name" = "azuredisk-premium-retain"
    }
    "parameters" = {
      "kind" = "Managed"
      "storageaccounttype" = "Standard_LRS"
    }
    "provisioner" = "kubernetes.io/azure-disk"
    "reclaimPolicy" = "Delete"
    "volumeBindingMode" = "WaitForFirstConsumer"
  }
}

resource "kubernetes_manifest" "persistentvolumeclaim_azure_managed_disk_pvc" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "PersistentVolumeClaim"
    "metadata" = {
      "name" = "azure-managed-disk-pvc"
       "namespace" = "default"  # Replace with your desired namespace
    }
    "spec" = {
      "accessModes" = [
        "ReadWriteOnce",
      ]
      "resources" = {
        "requests" = {
          "storage" = "1Gi"
        }
      }
      "storageClassName" = "azuredisk-premium-retain"
    }
  }
depends_on=[kubernetes_manifest.storageclass_azuredisk_premium_retain]
}

resource "kubernetes_manifest" "pod_newpod" {
  manifest = {
    apiVersion = "v1"
    kind       = "Pod"
    metadata = {
      name      = "newpod"
      namespace = "default"
    }
    spec = {
      containers = [
        {
          image = "nginx:latest"
          name  = "newpod"
          volumeMounts = [
            {
              mountPath = "/mnt/azure"
              name      = "volume"
            },
          ]
        },
      ]
      volumes = [
        {
          name = "volume"
          persistentVolumeClaim = {
            claimName = "azure-managed-disk-pvc"
          }
        },
      ]
    }
  }
depends_on=[kubernetes_manifest.storageclass_azuredisk_premium_retain,kubernetes_manifest.persistentvolumeclaim_azure_managed_disk_pvc]
}
*/
