terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 7.0" # access_config (modo API) existe desde 5.33; compatível com environments/ (~> 5.0)
    }
  }
}
