resource "tls_private_key" "windows_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "windows_key" {
    key_name = "capstone-windows-key"
    public_key = tls_private_key.windows_key.public_key_openssh
}