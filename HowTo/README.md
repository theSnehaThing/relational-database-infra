# User Management Script

Simple script to add users to database infrastructure environments.

## Usage

```bash
./add-users.sh <users.csv> <environment>
```

## Steps

1. **Fill users.csv** with your user data:
```csv
FirstName,LastName,Email,Role
Piet,Pietersen,piet@2solar.nl,developer
Klaas,Klassen,klass@2solar.nl,admin

```
Don't forget the new line at the end of users.csv

2. **Run the script** with environment:
```bash
./add-users.sh users.csv local
```

3. **Script will**:
   - Validate CSV format and data
   - Check environment exists
   - Add users to environment tfvars
   - Run terraform workflow
   - Show created resources
   - Reset CSV for next use

## Requirements

- All CSV fields are mandatory
- Valid roles: `developer`, `admin`, `manager`
- Environment file must exist: `envs/{env}.tfvars`
- Terraform must be installed

## Examples

```bash
# Local environment
./add-users.sh users.csv local

# Development environment  
./add-users.sh users.csv dev

# Production environment
./add-users.sh users.csv prod
```

## Output

After successful execution, you'll see:
- IAM usernames
- Database schema names  
- Secret names for credentials
- Access permissions granted

The CSV file gets reset to headers only after successful completion.

