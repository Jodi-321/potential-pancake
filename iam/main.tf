resource "aws_iam_role" "ssm_instance_role" {
    name = "capstone-ssm-role"

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

    tags = {
        Name = "capstone-ssm-role"
        Project = "Capstone"
    }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
    role = aws_iam_role.ssm_instance_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
    name = "capstone-ssm-instance-profile"
    role = aws_iam_role.ssm_instance_role.name
}