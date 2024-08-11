variable "instance_name" {
  type = string
}

variable "env" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-1"
}

variable "instances" {
  type = map(map(any))
}

variable "ami" {
  type    = string
  default = "ami-067f9151a94af1e4f"
}

variable "user_data" {
  type    = string
  default = ""
}

variable "vpc_cidr" {
  type    = string
  default = "10.99.0.0/18"
}

variable "vpc_subnet" {
  type    = string
  default = "10.99.0.0/24"
}
