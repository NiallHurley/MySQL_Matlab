# MySQL_Matlab
Matlab Class for interacting with MySQL database from Matlab using the JDBC connector

A class which connects to MySQL 'hostname' using 'username' and 'password' using JDBC driver (which may need to be separately installed/added to javaclasspath

Can be used to query and return data (use method 'getData') or to execute statements which do not return data (use method 'query') 

methods of interest: 
Open, Close, GetData, Query (the latter verify if connection is open before proceeding).

## Files 
- **MySQLDatabase.m**  - class file. 
- **MySQLDatabase.m**  - unit test file. 

##Adding  JDBC Connector to Matlab
Follow the instructions on [the Mathworks site](http://uk.mathworks.com/help/database/ug/mysql-jdbc-windows.html) under the heading "Step 2. Add the JDBC driver to the MATLAB static Java class path."

The JDBC connector is available on [mysql.com](https://dev.mysql.com/downloads/connector/j/) and is a file with name like: mysql-connector-java-X.X.XX.jar
## Example
```
% Set up a connection:
p = MySQLDatabase('localhost','username','password1234');
p.verbose = true;
disp(p)
% then either execute a query:
p.Query('UPDATE `all_info_db`.`contract_info` SET `Active Start Date`=''2015-02-01'' WHERE `ID`=''1'';');
  
% or get data using a select query:
p.Query('select * from `all_info_db`.`contract_info` order by id desc  limit 3');
[data,fieldNames] = p.getData(); % return cell array of data
```
## Unit test
Unit Test for MySQLDatabase. 
   Run using runtest command 
   e.g.
     runtest(path_to_folder_containing_unit_test)
     
  this user operates on schema 'test'
  GRANT USAGE ON *.* TO 'test_user'@'localhost' IDENTIFIED BY PASSWORD '*C83F5917FBCCAABBF440436C9A977C383E850272'
  GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, EXECUTE ON `test`.* TO 'test_user'@'localhost'

## Help 
As with all Matlab files, at the prompt type:
```
help <command>
```
or 
```
doc <command>
```
	

