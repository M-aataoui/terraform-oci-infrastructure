output "public_ip" {
  description = "IP publique du serveur e-learning"
  value       = oci_core_instance.app_server.public_ip
}