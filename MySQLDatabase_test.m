classdef MySQLDatabase_test < matlab.unittest.TestCase
    
    % this user operates on schema 'test'
    % GRANT USAGE ON *.* TO 'test_user'@'localhost' IDENTIFIED BY PASSWORD '*C83F5917FBCCAABBF440436C9A977C383E850272'
    % GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, EXECUTE ON `test`.* TO 'test_user'@'localhost'
    properties (SetAccess = private,Hidden=true)        
        hostName ='localhost';              %The database host
        userName ='test_user';              %The userName for the database
        password ='fcec49718c29530c052285539a09584c';         
    end
    
    methods(Test)
        
        function test_full(testCase)
            p = MySQLDatabase(testCase.hostName,testCase.userName,testCase.password);
            
            createquery = ['CREATE  TABLE `test`.`test_table` ( ' ...
                '  `ID` INT NOT NULL AUTO_INCREMENT , ' ...
                '  `DateTime` DATETIME NULL , ' ...
                '  `Integer` INT NULL , ' ...
                '  `Decimal` DECIMAL(10) NULL , ' ...
                '  `Date` DATE NULL , ' ...
                '  `Time` TIME NULL , ' ...
                '  `Timestamp` TIMESTAMP NULL , ' ...
                '  PRIMARY KEY (`ID`) ); ' ];
            p.Query(createquery);
                        
            insertquery = {'INSERT INTO `test`.`test_table` (`DateTime`, `Integer`, `Decimal`, `Date`, `Time`) VALUES (''2016-03-24 01:02:03'', ''1'', ''1.23456789'', ''2016-03-24'', ''01:02:03'');'
                'INSERT INTO `test`.`test_table` (`DateTime`, `Integer`, `Decimal`) VALUES (''2017-03-24 01:02:03'', ''3'', ''24'');'
                'INSERT INTO `test`.`test_table` (`Decimal`, `Date`, `Time`) VALUES (''1.234567891011'', ''2016-03-24'', ''01:02:03'');'};
            for  i = 1:3
                p.Query(insertquery{i});
            end
            
            selectQuery = 'SELECT * FROM test.test_table;';
            p.Query(selectQuery);
            [tdata, tfields] = p.GetData();
                        
            dropQuery = 'Drop table test.test_table;';
            p.Query(dropQuery);
            
            truefields = {'ID'    'DateTime'    'Integer'    'Decimal'    'Date'    'Time'    'Timestamp'};
            assert(isequal(truefields,tfields),' Field names don''t match')
                        
            truedata = reshape({ [1]    [2]    [3]    '2016-03-24 01:02:03.0'    '2017-03-24 01:02:03.0'    []    [1]    [3] []    [1]    [24]    [1]    '2016-03-24'    []    '2016-03-24'    '01:02:03'    [] '01:02:03'    []    []    []},size(tdata)); %#ok<NBRAK>
            assert(isequal(truedata,tdata),' Field names don''t match');                        
        end
        
        function test_open_connection_error(testCase)
            p = MySQLDatabase(testCase.hostName,testCase.userName,'');
            testCase.verifyError(@()p.Open,'MySQLDatabase:ConnectionError')            
        end 
        
        function test_query_error(testCase)
            p = MySQLDatabase(testCase.hostName,testCase.userName,testCase.password);
            testCase.verifyError(@()p.Query('nonsense;'),'MySQLDatabase:QueryError')  
        end
    end
    
end