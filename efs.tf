provider "aws" {
  region = "ap-south-1"
  profile = "prem"
}
resource "aws_security_group" "allow_http_ssh" {
  name        = "security_created_by_terraform"
  description = "Allow TLS inbound traffic"
  vpc_id      = "vpc-73f5ea1b"

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}
resource "aws_security_group" "allow_nfs_2049" {
  name        = "security_created_by_terraform_for_efs"
  description = "Allow TLS inbound traffic NFS"
  vpc_id      = "vpc-73f5ea1b"

  ingress {
    description = "TLS from VPC"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "NFS"
  }
}
resource "aws_instance" "webserver" {
   depends_on = [
  aws_security_group.allow_http_ssh ,
     ]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups = [ "security_created_by_terraform" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/kiren/Downloads/mykey.pem")
    host     = aws_instance.webserver.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo yum install amazon-efs-utils -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }

  tags = {
    Name = "myos"
  }

}

resource "aws_efs_file_system" "efs" {
    depends_on = [
  aws_instance.webserver ,
     ]
  creation_token = "my-product"
  tags = {
    Name = "MyProduct"
  }
}
resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.efs.id
}

resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_instance.webserver.subnet_id
  security_groups = [aws_security_group.allow_nfs_2049.id, ]
}

resource "null_resource" "nullremote3"  {
    depends_on = [
        aws_efs_mount_target.alpha,
    ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/kiren/Downloads/mykey.pem")
    host     = aws_instance.webserver.public_ip
  }
 provisioner "remote-exec" {
    inline = [
      "sudo mount -t efs -o tls ${aws_efs_file_system.efs.id}:/ /var/www/html/",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Premchandg278/aws_web.git /var/www/html/"
    ]
  }
}
resource "null_resource" "nulllocal1"  {
 depends_on = [
    null_resource.nullremote3,
  ]
	provisioner "local-exec" {
	    command = "echo This is your web server ip ${aws_instance.webserver.public_ip}"
  	}
}


