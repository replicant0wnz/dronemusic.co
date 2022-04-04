terraform {
  required_providers {
      aws = "~> 3.74"
  }
}

provider "aws" {
  region = "us-east-1" // The region for the S3 buckets and the CloudFront distribution
}

module "website" {
  source = "buildo/website/aws"
  domain = "dronemusic.co" 
}
