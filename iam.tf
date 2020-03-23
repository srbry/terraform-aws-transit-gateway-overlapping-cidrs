resource "aws_iam_role" "poc-vpc-transit-nat-role" {
  name = "poc-vpc-transit-nat-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "poc-vpc-transit-nat-role-policy" {
  name = "poc-vpc-transit-nat-role-policy"
  role = aws_iam_role.poc-vpc-transit-nat-role.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRouteTables",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:CreateRoute",
        "ec2:ReplaceRoute",
        "ec2:DeleteRoute",
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:DescribeTransitGatewayAttachments",
        "ec2:DescribeTransitGatewayRouteTables",
        "logs:Create*",
        "logs:PutLogEvents"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "poc-vpc-transit-nat" {
  name = "poc-vpc-transit-nat"
  role = aws_iam_role.poc-vpc-transit-nat-role.name
}
