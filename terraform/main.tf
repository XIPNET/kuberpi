provider "kubernetes" {
  host = "https://10.10.0.100:6443"

  client_certificate		= "${file("./terraform.crt")}"
  client_key			= "${file("./terraform.key")}"
  cluster_ca_certificate	= "${file("./ca.crt")}"
}
