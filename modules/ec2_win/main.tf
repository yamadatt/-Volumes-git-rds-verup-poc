variable "vpc_id" {}
variable "env" {}
variable "name_prefix" {}
variable "subnet_1a_id" {}
variable "subnet_1b_id" {}
variable "instace_spec" {}
variable "sg_ec2_win_id" {}
variable "win_ami_id" {}
# DB操作用のWindowsEC2


# data "aws_ami" "windows-2022" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["*Windows_Server-2022-Japanese-Full-Base*"]
#   }
# }
# output "ami_id" {
#   value = data.aws_ami.windows-2022.id
# }


resource "aws_instance" "windows" {
  # ami = data.aws_ami.windows-2022.id
  ami                         = var.win_ami_id
  instance_type               = var.instace_spec
  subnet_id                   = var.subnet_1a_id
  vpc_security_group_ids      = [var.sg_ec2_win_id]
  source_dest_check           = false
  key_name                    = "radio"
  associate_public_ip_address = true

  user_data = <<-EOT
    <powershell>
    # タイムゾーンを東京標準時に設定
    Set-TimeZone -Id "Tokyo Standard Time"

    # レジストリ設定を変更して再起動後もJSTを維持
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'TimeZoneKeyName' -Value 'Tokyo Standard Time'
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' -Name 'ActiveTimeBias' -Value 540
    </powershell>
  EOT

  # root disk
  root_block_device {
    volume_size           = 40
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }


  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${var.name_prefix}-windows-server"

  }
}




resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}


