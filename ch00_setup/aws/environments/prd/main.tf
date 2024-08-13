module "ec2" {
  source = "../../"

  instance_name = "seccamp-b6"
  env           = "prd"
  region        = "ap-northeast-1"
  ami           = "ami-0e44d8473bfd756ed" # /aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id
  user_data     = file("${path.module}/userdata.bash")

  instances = {
    "00" = {
      instance_type = "m4.xlarge"
      volume_size   = 40
    }
    # "01" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "02" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "03" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "04" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "05" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "06" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "07" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "08" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "09" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "10" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "11" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "12" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "13" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "14" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
    # "15" = {
    #   instance_type = "m4.xlarge"
    #   volume_size   = 40
    # }
  }
}
