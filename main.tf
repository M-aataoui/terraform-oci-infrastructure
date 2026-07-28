# ------------------------------------------------------------------------------
# 1. RECUPERATION DE L'AVAIABILITY DOMAIN & IMAGE UBUNTU
# ------------------------------------------------------------------------------
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Image Ubuntu 22.04 LTS pour architecture ARM (A1)
data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# ------------------------------------------------------------------------------
# 2. RESEAU (VCN, Subnet, Internet Gateway, Route Table)
# ------------------------------------------------------------------------------
resource "oci_core_vcn" "elearning_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "elearning-vcn"
  dns_label      = "elearningvcn"
}

resource "oci_core_internet_gateway" "elearning_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.elearning_vcn.id
  display_name   = "elearning-internet-gateway"
  enabled        = true
}

resource "oci_core_route_table" "elearning_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.elearning_vcn.id
  display_name   = "elearning-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.elearning_ig.id
  }
}

# ------------------------------------------------------------------------------
# 3. PARE-FEU / SECURITY LIST (SSH, HTTP, HTTPS)
# ------------------------------------------------------------------------------
resource "oci_core_security_list" "elearning_sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.elearning_vcn.id
  display_name   = "elearning-security-list"

  # Trafic sortant illimité
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # Port 22 (SSH)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow SSH access"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Port 80 (HTTP)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow HTTP traffic"
    tcp_options {
      min = 80
      max = 80
    }
  }

  # Port 443 (HTTPS)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow HTTPS traffic"
    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.elearning_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "elearning-public-subnet"
  dns_label         = "publicsubnet"
  route_table_id    = oci_core_route_table.elearning_rt.id
  security_list_ids = [oci_core_security_list.elearning_sl.id]
}

# ------------------------------------------------------------------------------
# 4. INSTANCE COMPUTE (VM ALWAYS FREE ARM)
# ------------------------------------------------------------------------------
resource "oci_core_instance" "app_server" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "elearning-dev-vm"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
  }
  
  metadata = {
    ssh_authorized_keys = file("C:/Users/HP/Desktop/cle.key.pub")
  }
}