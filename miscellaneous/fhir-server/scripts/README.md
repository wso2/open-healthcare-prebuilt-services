# Create Database Tables in FHIR Repository

To create the necessary database tables in the FHIR repository, you can use the following SQL script. This script will 
set up the required tables for storing FHIR resources and related metadata.

Run the following sql schema script against your database to create the necessary tables based on your Database Type.

### For PostgreSQL

Run [schema-postgresql.sql](schema-postgresql.sql)

### For H2

Run [schema-h2.sql](schema-h2.sql)

## Persist data to the SEARCH_PARAM_RES_EXPRESSIONS table

After creating the tables, you need to populate the `SEARCH_PARAM_RES_EXPRESSIONS` table with the appropriate search 
parameter expressions. This is crucial for enabling efficient searching and indexing of FHIR resources.

Required expressions are defined in [r4-searchParam-Expression.csv](..%2Fassets%2Fr4-searchParam-Expression.csv) file.

In order to generate the insert statements, you can use the following script:
Run [populate_search_param_expression.sh](populate_search_param_expression.sh) script using below commands. 
The script generates the insert statements and saves them to `insert_SEARCH_PARAM_RES_EXPRESSIONS_<DBType>.sql` file. 
You can then execute the generated SQL file against your database.
