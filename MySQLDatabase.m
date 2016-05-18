%MYSQLDATABASE
%     A class which connects to MySQL 'hostname' using 'username' and
%     'password' using JDBC driver (which may need to be separately
%     installed/added to javaclasspath
% 
%     Can be used to query and return data (use method 'getData')
%     or to execute statements which do not return data (use method 'query')
% 
%     methods of interest: Open, Close, GetData, Query (the latter verify if
%     connection is open before proceeding). 
% 
%   Examples:
% 
%     % Set up a connection:
%     p = MySQLDatabase('localhost',DB_USER,DB_PWD);
%     p.verbose = true;
%     disp(p)
%     % then either execute a query:
%     p.Query('UPDATE `all_info_db`.`contract_info` SET `Active Start Date`=''2015-02-01'' WHERE `ID`=''1'';');
% 
%     % or get data using a select query:
%     p.Query('select * from all_info_db.contract_info order by id desc  limit 3');
%     [data,fieldNames] = p.GetData();
% 
%     Note that the GetData method will execute a query (i.e. UPDATE/INSERT but
%     will return an error as there is no data to be returned.
% 
%     Useful information:
%       - https://docs.oracle.com/javase/7/docs/api/java/sql/ResultSet.html
%       - https://docs.oracle.com/javase/7/docs/api/java/sql/ResultSetMetaData.html

% To install driver:
%  Follow the instructions
%  on http://uk.mathworks.com/help/database/ug/mysql-jdbc-windows.html
%  under the heading
%  "Step 2. Add the JDBC driver to the MATLAB static Java class path."

classdef MySQLDatabase < handle
    properties (SetAccess = protected)
        connection                 %The database connection
        hostName               %The database host
        userName               %The userName for the database
        statement
        resultset
    end
    
    properties (SetAccess = public)
        verbose = false;
    end
    
    properties (SetAccess = protected,Hidden=true)
        password = '';         
        %The database password
    end
    
    methods (Hidden = true)
        % Constructor
        function this = MySQLDatabase(hostName,userName,password)
            %             if nargin<3
            %                 error(1);
            %             end
            %
            this.hostName = hostName;
            this.userName = userName;
            this.password = password;
        end                               
        
        function CloseStatement(this)
            %    closes statement (after checking for closed resultset)
            if ~isempty(this.statement)
                if ~isempty(this.resultset)
                    this.resultset.close();
                    this.resultset=[];
                    VerbosePrint(this,'resultset closed')
                end
                this.statement.close();
                this.statement = [];
                VerbosePrint(this,'statement closed')
            end
        end
        
        function VerbosePrint(this,messageString)
            % if this flag is set to true then extra information is
            % displayed in the command window (usually for debugging)
            if this.verbose
                disp([datestr(now,'HH:MM:SS') ' DEBUG: ' messageString]);
            end
        end
    end
    methods
        function Open(this)
            % Opens a MySQL database connection
            if isempty(this.connection)
                VerbosePrint(this,['connecting to db ' this.userName '@' this.hostName]);
                try
                    properties = java.util.Properties();
                    properties.setProperty('user', this.userName);
                    properties.setProperty('password', this.password);
                    properties.setProperty('zeroDateTimeBehavior', 'convertToNull');
                    %                     ?zeroDateTimeBehavior=convertToNull
                    driver = javaObjectEDT('com.mysql.jdbc.Driver');
                    url = ['jdbc:mysql://' this.hostName '/' ];
                    this.connection = driver.connect(url, properties);
                catch exception
                    throw(MException('MySQLDatabase:ConnectionError', char(exception.message)));
                end
            end
            %             disp('opened')
        end 
        
        function Close(this)
            % Closes the MySQL database connection
            if ~isempty(this.connection)
                this.CloseStatement();
                this.connection.close();
                this.connection = [];
                VerbosePrint(this,['closing connection to db ' this.userName '@' this.hostName])
            end
        end
        
        function result = Query(this,queryString)
            % QUERY - Executes the MySQL query
            % input:  queryString
            % output: result (boolean, true if success)
            %
            this.CloseStatement();
            this.Open();
            VerbosePrint(this,queryString);
            try
                this.statement = this.connection.createStatement();
                if this.statement.execute(queryString)
                    this.resultset =this.statement.getResultSet();
                    result = true;
                else
                    result = false;
                end
            catch exception
                throw(MException('MySQLDatabase:QueryError', char(exception.message)));
            end
        end
        
        function [data,fieldNames] = GetData(this)
            % gets the data returned by the query
            if isempty(this.resultset)
                throw(MException('MySQLDatabase:QueryError','No resultset available.'));
            end
            metaData = this.resultset.getMetaData();
            numcols = metaData.getColumnCount();
            
            % count rows
            this.resultset.last();
            numrows = this.resultset.getRow();
            this.resultset.first();
            VerbosePrint(this,['Result set size: ' num2str(numrows) ' x ' num2str(numcols)])
            
            % Allocate Space for result: - all db nulls will be converted to {[]} types
            data       = cell(numrows,numcols);
            fieldNames = cell(1,numcols);
            colTypes   = cell(1,numcols);
            
            for coli = 1:numcols
                fieldNames{coli} = char(metaData.getColumnLabel(coli));
                colTypes{coli} = char(metaData.getColumnTypeName(coli));
            end
            
            if this.resultset.first()   % if there exists a first row...
                rowi = 0;
                while 1
                    rowi = rowi + 1;
                    for coli = 1:numcols
                        value = this.resultset.getObject(coli);
                        if ~this.resultset.wasNull() % this doesn't take a column index as it looks at last read db cell value
                            switch colTypes{coli}
                                case {'DECIMAL','BIGINT UNSIGNED'}
                                    data{rowi,coli} = double(value);
                                case {'DATETIME','DATE','TIME'}
                                    if ~isempty(value)
                                        data{rowi,coli} =char(value); % this is better
                                    end
                                otherwise
                                    data{rowi,coli} = value;
                            end
                        end
                    end
                    if ~this.resultset.next()
                        break;
                    end
                end
            end
        end                
    end
end


