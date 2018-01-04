# Hive To RDBMS

This workflow is used to move data from HDFS to an RDBMS like MySql.

If starts by issuing a Hive query that will dump the results to a specific directory on HDFS.  

The file(s) created by the Hive query need to be in Text format and match the field delimiter you will specify in the properties.
 
## Setup

1. Copy this workflow to HDFS
2. Put a copy of your hive-site.xml on HDFS and identify the location in the properties
3. Build a properties file, based on this [template](../../../test/resources/oozie.workflow/hive.to.rdbms.properties) 
4. Copy the RDBMS jdbc jar file the the workflows *lib* directory.  You will need to create this.
5. Copy the referenced hive query file to the workflows *hive* directory.  You will need to create this.

## Reuse

You do NOT need to replicate this workflow in HDFS for each process.  Use a different properties file to initial the workflow.  Multiple Hive SQL files can exist in the workflows *hive* directory.

## Things that can go wrong

### Permissions

The job will fail during the Hive step if the user running the job from Oozie doesn't have access to the directories that the Hive query reads from or to.

### Sqoop Connection

The jdbc driver needs to be added to this workflows *lib* directory.  This will ensure the jdbc drivers are in the classpath.

### Hive SQL Query File

Needs to be in the *hive* sub-directory of the deployed workflow

### Handling NULLS

Coordinate the have query output of nulls with the null criteria feed into the Sqoop job.

### Field Order

The Hive Query Field Order output MUST match the target RDBMS field order.