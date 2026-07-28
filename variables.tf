variable "tenancy_ocid" {
  type        = string
  description = "OCID du Tenancy OCI"
}

variable "user_ocid" {
  type        = string
  description = "OCID de l'utilisateur OCI"
}

variable "fingerprint" {
  type        = string
  description = "Empreinte digitale de la clé API OCI"
}

variable "private_key_path" {
  type        = string
  description = "Chemin vers la clé privée RSA (.pem)"
}

variable "compartment_ocid" {
  type        = string
  description = "OCID du compartiment de déploiement"
}

variable "region" {
  type        = string
  description = "Région OCI (ex: af-casablanca-1)"
  default     = "af-casablanca-1"
}