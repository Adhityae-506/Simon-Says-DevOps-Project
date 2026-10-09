resource "aws_route_table" "simon_route_table" {
  vpc_id = aws_vpc.simon_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.simon_igw.id
  }

  tags = {
    Name = "simon-says-rt"
  }
}

resource "aws_route_table_association" "rt_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.simon_route_table.id
}


resource "aws_route_table_association" "rt_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.simon_route_table.id
}