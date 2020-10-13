# Hybrid-Multi-Cloud-Task2
<pre>
Task-2 details

1. Create Security group which allow the port 80.
2. Launch EC2 instance.
3. In this Ec2 instance use the existing key or provided key and security group which we have created in step 1.
4. Launch one Volume using the EFS service and attach it in your vpc, then mount that volume into /var/www/html
5. Developer have uploded the code into github repo also the repo has some images.
6. Copy the github repo code into /var/www/html
</pre>
# How to use this code
<pre>
1. First download terraform code
2. Do some changes in code
   change aws profile name 
   change private key path in code
   Change github repo url
3. Run command <b>terraform init</b>
4. Run command <b>terraform apply </b>
</pre>
# Create Terrafoem code
<pre>

provider "aws" {
  region = "ap-south-1"
  profile = "prem"   <b> # change aws profile name </b>
}
</pre>
# Create Security group which allow the port 80 and 22.

<pre>
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
}</pre>
# Create a security group which allow 2049 port to connect EFS storage

<pre>
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
}</pre>
# creating aws instance 

<pre>
resource "aws_instance" "webserver" {
   depends_on = [
  aws_security_group.allow_http_ssh ,
     ]
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "mykey"
  security_groups = [ "security_created_by_terraform" ]
 </pre>
  # connect to aws instance
<pre>
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/kiren/Downloads/mykey.pem") <b># change private key path </b> 
    host     = aws_instance.webserver.public_ip
  }</pre>
# install php , amazon-efs-utils , git ,httpd in aws instance  and start httpd service  

<pre>
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
</pre>
# create a EFS file system

<pre>
resource "aws_efs_file_system" "efs" {
    depends_on = [
  aws_instance.webserver ,
     ]
  creation_token = "my-product"
  tags = {
    Name = "MyProduct"
  }
}


</pre>
# Create a access point

<pre>
resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.efs.id
}</pre>
# create mount target

<pre>
resource "aws_efs_mount_target" "alpha" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_instance.webserver.subnet_id
  security_groups = [aws_security_group.allow_nfs_2049.id, ]
}
</pre>
# Connect to aws instance and mount EFS storage
<pre>
resource "null_resource" "nullremote3"  {
    depends_on = [
        aws_efs_mount_target.alpha,
    ]
    </pre>
# Use ssh protocol to connect aws instance
  <pre>
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/kiren/Downloads/mykey.pem") <b># change private key path</b>
    host     = aws_instance.webserver.public_ip
  }
  </pre>
 # Run some commands to mount EFS storage , download webpages from github in aws instance
 <pre>
 provisioner "remote-exec" {
    inline = [
      "sudo mount -t efs -o tls ${aws_efs_file_system.efs.id}:/ /var/www/html/",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Premchandg278/aws_web.git /var/www/html/" <b> # Change github repo url </b>
    ]
  }
}
</pre>
# Run echo command in local system and show public ip of aws instance
<pre>
resource "null_resource" "nulllocal1"  {
 depends_on = [
    null_resource.nullremote3,
  ]
	provisioner "local-exec" {
	    command = "echo This is your web server ip ${aws_instance.webserver.public_ip}"
  	}
}
</pre>
