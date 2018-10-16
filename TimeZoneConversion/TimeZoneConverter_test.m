classdef TimeZoneConverter_test < matlab.unittest.TestCase
    
    % this user operates on schema 'test'
    % GRANT USAGE ON *.* TO 'test_user'@'localhost' IDENTIFIED BY PASSWORD '*C83F5917FBCCAABBF440436C9A977C383E850272'
    % GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, EXECUTE ON `test`.* TO 'test_user'@'localhost'
    properties (SetAccess = private,Hidden=true)
        hostName ='localhost';   %The database host
        userName ='test_user';   %The userName for the database
        password ='fcec49718c29530c052285539a09584c';        
        % % % useful for testing: p = MySQLDatabase(hostName,userName,password);
        mysqlConn
    end
    properties (SetAccess = private)
        %first col is UTC
        testVectors  = {'2015-06-03 06:00:00','2015-06-03 01:00:00','America/Chicago'
            '2015-06-03 06:00:00','2015-06-03 07:00:00','Europe/Dublin'
            '2015-06-03 06:00:00','2015-06-03 10:00:00','Europe/Samara'
            '2015-06-03 06:00:00','2015-06-03 09:00:00','Europe/Moscow'
            '2003-11-08 05:00:00','2003-11-07 22:00:00','America/Ojinaga'
            '2003-11-08 05:00:00','2003-11-08 05:00:00','Europe/Dublin'
            '2003-02-08 05:00:00','2003-02-08 05:00:00','Europe/Dublin'
            '2003-06-08 05:00:00','2003-06-08 06:00:00','Europe/Dublin'
            '1975-10-15 00:00:00','1975-10-15 01:00:00','Europe/London'
            '2014-02-06 08:00:00','2014-02-06 21:00:00','Antarctica/McMurdo'
            '2014-12-21 16:49:00','2014-12-22 06:49:00','Pacific/Apia'
            '2009-11-01 02:30:00','2009-11-01 00:00:00','America/St_Johns'
            '2009-11-01 03:35:00','2009-11-01 00:05:00','America/St_Johns'
            '2001-10-18 20:30:00','2001-10-18 23:30:00','Asia/Hebron'
            '2001-10-18 22:00:00','2001-10-19 00:00:00','Asia/Hebron'
            '1994-10-30 07:15:00','1994-10-30 01:15:00','America/Yellowknife'
            '1993-03-27 20:00:00','1993-03-28 08:00:00','Asia/Magadan'};
    end
    
    methods(TestClassSetup)
        function initialiseConnector(testCase)
            testCase.mysqlConn =  MySQLDatabase(testCase.hostName,testCase.userName,testCase.password);
            testCase.mysqlConn.verbose = false;
        end
    end    
    methods(TestClassTeardown)
    end
    
    methods(Test)
        function test_timezoneTablesExist(testCase)
            tzc = TimeZoneConverter(testCase.mysqlConn);
            tzc.Convert(now,'UTC','Europe/Dublin');            
        end
         
        function test_convertSameTimezone(testCase)
            tzc = TimeZoneConverter(testCase.mysqlConn);
            out = tzc.Convert(now,'UTC','UTC');
            assert(isnumeric(out),'output should be numeric');
            out = tzc.Convert(now*ones(1,10),'UTC','UTC');
            assert(isnumeric(out),'output should be numeric');
            dt = floor(now)+1/24;
            assert(isequal([1,2;3,4],tzc.Convert(dt + [1,2;3,4],'UTC','UTC')-dt),'unexpected output - should be 2x2 matrix')
        end
                         
        function test_convertTestVectors(testCase)
            tzc = TimeZoneConverter(testCase.mysqlConn);
            vlen = size(testCase.testVectors,1);
            vUTC = datenum(testCase.testVectors(:,1));
            vLocal = datenum(testCase.testVectors(:,2));
            timezones = testCase.testVectors(:,3);
            vUTCToLocal = zeros(vlen,1);
            vLocalToUTC = zeros(vlen,1);
            for vi = 1:vlen
                vUTCToLocal(vi) = tzc.Convert(vUTC(vi),'UTC',timezones{vi});
                vLocalToUTC(vi) = tzc.Convert(vLocal(vi),timezones{vi},'UTC');
            end
            assert(all(vUTCToLocal(:)==vLocal(:)),['Conversion from UTC to Local giving some unexpected results in ' num2str(sum(~(vUTCToLocal(:)==vLocal(:)))) '/' num2str(vlen) ' cases']);
            assert(all(vLocalToUTC(:)==vUTC(:)),['Conversion from Local to UTC giving some unexpected results in ' num2str(sum(~(vLocalToUTC(:)==vUTC(:)))) '/' num2str(vlen) ' cases']);
        end
        
        function test_nonDateInput_error(testCase)
            tzc = TimeZoneConverter(testCase.mysqlConn);
            testCase.verifyError(@()tzc.Convert('nonsense;'),'TimeZoneConverter:InvalidInput')
        end
        
        function test_badConversion_error(testCase)
            tzc = TimeZoneConverter(testCase.mysqlConn);
            testCase.verifyError(@()tzc.Convert(now,'badTimeZone','UTC'),'TimeZoneConverter:ConvertError')
        end
        
        function test_badConstruction_error(testCase)
            testCase.verifyError(@()TimeZoneConverter('dummy_input_parameter1'),'TimeZoneConverter:InvalidInput');
        end
        
    end
end