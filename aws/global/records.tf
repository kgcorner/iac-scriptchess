locals {
  # key => record. The key is only a handle for OpenTofu; name and type identify the record in Route 53.
  records = {
    # ---- mail (Google)
    mx_apex = {
      name    = "scriptchess.com"
      type    = "MX"
      records = ["1 SMTP.GOOGLE.COM", "15 swxezbxah6flgnhodzelrrrxalwszpczwxxixitx3wqkfqutsjca.mx-verification.google.com."]
    }
    txt_apex = {
      name = "scriptchess.com"
      type = "TXT"
      records = [
        "\"google-site-verification=6nxgh9VvJ3H_nHd6J1jh9elweVGGWvcz2XZ0oyu6-Ms\"",
        "\"igleot1pvm\"",
      ]
    }
    dmarc = {
      name    = "_dmarc.scriptchess.com"
      type    = "TXT"
      records = ["\"v=DMARC1; p=none;\""]
    }

    # ---- Mailchimp DKIM. WARNING: the names have the domain twice, so these records do not work as DKIM.
    # Imported as they are; fixing the names is a separate change.
    dkim_k2 = {
      name    = "k2._domainkey.scriptchess.com.scriptchess.com"
      type    = "CNAME"
      records = ["dkim2.mcsv.net"]
    }
    dkim_k3 = {
      name    = "k3._domainkey.scriptchess.com.scriptchess.com"
      type    = "CNAME"
      records = ["dkim3.mcsv.net"]
    }

    # ---- servers
    api = {
      name    = "api.scriptchess.com"
      type    = "A"
      records = ["13.126.2.16"] # an AWS address. Check that it is still yours.
    }
    blog = {
      name    = "blog.scriptchess.com"
      type    = "A"
      records = ["13.126.2.16"] # same address as api. Check that it is still yours.
    }
    blogv2 = {
      name    = "blogv2.scriptchess.com"
      type    = "A"
      records = ["168.144.69.161"]
    }
    v2 = {
      name    = "v2.scriptchess.com"
      type    = "A"
      records = ["146.190.11.214"]
    }

    # ---- site verification
    marga_txt = {
      name    = "marga.scriptchess.com"
      type    = "TXT"
      records = ["\"zzrkdcpuhw\""]
    }

    # ---- ACM certificate validation. Never delete these: ACM uses them to renew the certificates.
    acm_apex = {
      name    = "_743a53760e7db8b6d46a3808abec9582.scriptchess.com"
      type    = "CNAME"
      records = ["_71bf45d4f0c797d107d1793310c04df0.stwyzjdjkd.acm-validations.aws."]
    }
    acm_www = {
      name    = "_f455a6c66010b127a9d8b0f271c319a3.www.scriptchess.com"
      type    = "CNAME"
      records = ["_4574bd409f5b59cc50f427d9de99e1a9.stwyzjdjkd.acm-validations.aws."]
    }
    acm_dev = {
      name    = "_f57c96798f926e68c22410b33b61ee31.dev.scriptchess.com"
      type    = "CNAME"
      records = ["_b12d65d8254073b72debe4dcea4ad14b.dbspspvlns.acm-validations.aws."]
    }
  }
}

resource "aws_route53_record" "this" {
  for_each = local.records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = each.value.records
}
