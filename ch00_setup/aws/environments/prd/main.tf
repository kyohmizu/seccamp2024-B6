module "ec2" {
  source = "../../"

  env    = "prd"
  region = "ap-northeast-1"
  ami = "ami-0e44d8473bfd756ed" # /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id
  user_data = file("${path.module}/userdata.bash")

  instances = {
    "test" = {
      instance_type = "m4.xlarge"
      volume_size   = 40
    }
    "01" = {
      instance_type = "m4.xlarge"
      volume_size   = 40
    }
  }
}
