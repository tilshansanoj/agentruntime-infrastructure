FROM amazon/aws-cli:2.31.9

RUN yum update -y && yum install -y wget unzip

# Install Terraform
RUN wget https://releases.hashicorp.com/terraform/1.13.3/terraform_1.13.3_linux_amd64.zip
RUN mv terraform_* terraform.zip
RUN unzip terraform.zip
RUN mv terraform /usr/local/bin