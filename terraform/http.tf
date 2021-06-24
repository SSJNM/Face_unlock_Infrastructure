provider "aws"{
  region  = "ap-south-1"
  profile = "default"
}

resource "aws_instance" "myec2" {
  ami             = "ami-052c08d70def0ac62"
  instance_type   = "t2.micro"
  security_groups  = [ "mysecurity-group" ]
  key_name        = "aws_cloud_key"

  tags = {
    Name = "aws_terra_ec2"
  }
}

resource "null_resource" "nullexec1"{ 
  connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/nisha/Desktop/Curious/aws_cloud_key.pem")
      host        = aws_instance.myec2.public_ip
    }

  provisioner "remote-exec" {
    inline = [
    "sudo yum install httpd php git -y",
    "sudo systemctl restart httpd",
    "sudo systemctl enable httpd",
    "sudo setenforce 0"
    ]
  }
  depends_on = [ aws_instance.myec2 ]
}

resource "aws_ebs_volume" "my_pd" {
  availability_zone = aws_instance.myec2.availability_zone
  size              = 1

  tags = {
    Name = "my_pd"
  }

  depends_on = [ aws_instance.myec2 ]  

}

resource "aws_volume_attachment" "ebs_att" {
  device_name  = "/dev/sdh"
  volume_id    = aws_ebs_volume.my_pd.id
  instance_id  = aws_instance.myec2.id
  force_detach = true
  depends_on = [ aws_ebs_volume.my_pd ]
}

resource "null_resource" "nullexec2"{
  provisioner "remote-exec"{
    inline = [
    "echo y | sudo mkfs.ext4 /dev/xvdh",
    "sudo mount /dev/xvdh /var/www/html",
    "sudo rm -rf /var/www/html/* ",
    "sudo git clone https://github.com/SSJNM/webserver.git /var/www/html"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("C:/Users/nisha/Desktop/Curious/aws_cloud_key.pem")
      host        = aws_instance.myec2.public_ip
    }
    
  }
 depends_on = [ aws_volume_attachment.ebs_att, null_resource.nullexec1 ] 
}

output "IPAddress"{
  value = aws_instance.myec2.public_ip
}

resource "null_resource" "nullexec3"{
  provisioner "local-exec"{
    command = "microsoftedge ${aws_instance.myec2.public_ip}"
  }
  depends_on = [ null_resource.nullexec2 ]
}

