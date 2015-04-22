module "ami" {
  source        = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
  region        = "us-west-2"
  distribution  = "trusty"
  instance_type = "${var.instance_type}"
}

module "vpc" {
  source   = "./vpc"

  name = "ssh-proxy-example"

  cidr = "10.0.0.0/16"
  private_subnets = "10.0.1.0/24,10.0.2.0/24,10.0.3.0/24"
  public_subnets  = "10.0.101.0/24,10.0.102.0/24,10.0.103.0/24"

  region   = "us-west-2"
  azs      = "us-west-2a,us-west-2b,us-west-2c"
}

resource "aws_security_group" "allow_ssh_from_world" {
  name = "sshproxy_sg_allow_ssh_from_world"
  description = "sshproxy_sg_allow_ssh_from_world"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_internal_traffic" {
  name = "sshproxy_sg_allow_internal_traffic"
  description = "sshproxy_sg_allow_internal_traffic"
  vpc_id = "${module.vpc.vpc_id}"

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "-1"
    self = true
  }
}

resource "aws_instance" "public" {
  ami           = "${module.ami.ami_id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${element(split(",", module.vpc.public_subnets), count.index)}"

  vpc_security_group_ids = [
    "${aws_security_group.allow_internal_traffic.id}",
    "${aws_security_group.allow_ssh_from_world.id}",
  ]

  connection {
    user  = "ubuntu"
    agent = true
  }

  tags {
    Name = "public-instance"
  }
}


resource "aws_instance" "private" {
  ami           = "${module.ami.ami_id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${element(split(",", module.vpc.private_subnets), count.index)}"

  vpc_security_group_ids = [
    "${aws_security_group.allow_internal_traffic.id}",
  ]

  connection {
    user  = "ubuntu"
    agent = true
  }

  tags {
    Name = "private-instance"
  }


  /******************************
    vvv THIS WILL NOT WORK vvv
  *******************************/
  provisioner "remote-exec" {
    inline = "echo remote-exec works >> /tmp/remote-exec"
  }
  /******************************
    ^^^ LET'S MAKE IT WORK ^^^
  *******************************/
}

output "public_instance_ip" {
  value = "${aws_instance.public.public_ip}"
}

output "private_instance_ip" {
  value = "${aws_instance.private.private_ip}"
}
