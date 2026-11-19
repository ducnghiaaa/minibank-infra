# zone was created in the console; NS are delegated at GoDaddy
import {
  to = aws_route53_zone.main
  id = "Z0524474HG5AIAQLAIUA"
}

resource "aws_route53_zone" "main" {
  name    = "andrewnguyen.cloud"
  comment = ""

  # a new zone gets new NS and breaks the GoDaddy delegation
  lifecycle {
    prevent_destroy = true
  }
}
