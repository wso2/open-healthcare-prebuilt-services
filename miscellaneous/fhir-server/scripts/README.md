# Create Database Tables in FHIR Repository

To create the necessary database tables in the FHIR repository, you can use the following SQL script. This script will 
set up the required tables for storing FHIR resources and related metadata.

1. Run the following sql schema script against your database to create the necessary tables based on your Database Type.

    #### For PostgreSQL
    Run [schema-postgresql.sql](schema-postgresql.sql)


2. Then run insert_SEARCH_PARAM_RES_EXPRESSIONS_postgres.sql script to persist data to the SEARCH_PARAM_RES_EXPRESSIONS table.

    #### For SQL Server
    Run [insert_SEARCH_PARAM_RES_EXPRESSIONS_postgres.sql](insert_SEARCH_PARAM_RES_EXPRESSIONS_postgres.sql)

## Add New Search Parameter Expressions

Follow the below steps, in case if you want to add new search parameter expressions other than the expressions defined in the code.

1. Update the [r4-searchParam-Expression.csv](..%2Fassets%2Fr4-searchParam-Expression.csv) file with the new search parameter expressions. Make sure to follow the existing format and include all necessary fields.

2. Run [populate_search_param_expression.sh](populate_search_param_expression.sh) script using below commands. 

```bash 
   chmod +x populate_search_param_expression.sh
    ./populate_search_param_expression.sh
```

The script generates the insert statements and saves them to `insert_SEARCH_PARAM_RES_EXPRESSIONS_<DBType>.sql` file. 
You can then execute the generated SQL file against your database.
