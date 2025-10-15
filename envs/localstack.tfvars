# LocalStack Environment Configuration
aws_region = "eu-west-1"
environment = "local"
db_state = "active"

# Database Configuration
db_instance_class = "db.t3.micro"
db_engine = "mysql"
db_engine_version = "8.0"
db_allocated_storage = 20
publicly_accessible = false

# User Configuration  
create_user = true
user = [
  {
    first_name = "Piet"
    last_name  = "Pietersen"
    email      = "piet@2solar.nl"
    role       = "developer"

  },
  {
    first_name = "Klaas"
    last_name  = "Klassen"
    email      = "klass@2solar.nl"
    role       = "admin"
  },
  {
    first_name = "Piet"
    last_name  = "AnotherPiet"
    email      = "piet2@2solar.nl"
    role       = "developer"
  },
  {
    first_name = "Henk"
    last_name  = "Hendriksen"
    email      = "henk@2solar.nl"
    role       = "manager"
  },
  {
    first_name = "Jan"
    last_name  = "Jansen"
    email      = "jan@2solar.nl"
    role       = "developer"
  },
  {
    first_name = "Kees"
    last_name  = "Keessen"
    email      = "kees@2solar.nl"
    role       = "developer"
  },
  {
    first_name = "Kees"
    last_name  = "AnotherKees"
    email      = "kees2@2solar.nl"
    role       = "developer"
  },
]
