classdef TimeZoneConverter < handle
    % class which uses mysql connection to convert datetimes from one timezone to another.  
    properties (Access = protected)
        mysqlconn
        batchSizeForQuery = 5000;
    end
    methods
        function this = TimeZoneConverter(mysqlconn)
            % Constructor method - takes 'MySQLDatabase' class as input or
            % DatabaseConfig class
            if isa(mysqlconn,DatabaseConfig.ClassName)
                mysqlconn = MySQLDatabase(mysqlconn);
            end
            if ~isa(mysqlconn,MySQLDatabase.ClassName)
                throw(MException('TimeZoneConverter:InvalidInput',...
                    ['Input to constructor not of class ''' MySQLDatabase.ClassName '''']));
            end
            this.mysqlconn = mysqlconn;
        end
        function outDateTimes = Convert(this,inDateTimes,fromTimezone, toTimezone)
            % conversion routine...
            if ~isnumeric(inDateTimes)
                throw(MException('TimeZoneConverter:InvalidInput',...
                    'Input datetimes not numeric'));
            end
            % check to make sure that we need to do something
            if strcmp(fromTimezone,toTimezone)
                outDateTimes = inDateTimes;
            else
                outDateTimesCell = {};
                % pass datetimes as a list and reshape later...
                inDateTimes = inDateTimes(:);
                batchStartInds = 1:this.batchSizeForQuery:length(inDateTimes);
                batchEndInds   = [batchStartInds(2:end)-1 length(inDateTimes)];

                for i = 1:length(batchStartInds)
                    inds = batchStartInds(i):batchEndInds(i);
                    queryString= this.GenerateQuery(inDateTimes(inds),fromTimezone, toTimezone);
                    this.mysqlconn.Query(queryString);
                    batchDateTimesCell = this.mysqlconn.GetData;
                    if any(cellfun(@isempty, batchDateTimesCell))
                        throw(MException('TimeZoneConverter:ConvertError',...
                            ['Failed to convert ' fromTimezone ' to ' toTimezone '. Empty resultset from database.']));
                    end
                    % cell array returned... parse the output back to
                    % datenum...
                    singletonDimension = find(size(batchDateTimesCell)~=1);
                    if isempty(singletonDimension)
                        singletonDimension = 1;
                    end
                    outDateTimesCell = cat(singletonDimension,outDateTimesCell,batchDateTimesCell);
                end
                try
                    outDateTimes = DateUtils.parse(outDateTimesCell);
                catch
                    throw(MException('TimeZoneConverter:DateParseError',...
                        'Unable to parse datetime cell returned from db'));
                end
                outDateTimes = reshape(outDateTimes,size(inDateTimes));
            end
        end

    end
    methods (Access = private,Hidden,Static)
        function queryString = GenerateQuery(dateTimeList, fromTimezone, toTimezone)
            % FTR ... select union is faster than
            % 1. create temp table
            % 2. select convert tz returning one row
            % and similar speed to select convert_tz from union all select
            sz1 = length(dateTimeList);
            wmat = [repmat(' UNION ALL SELECT CONVERT_TZ(''',sz1,1) ...
                MySQLDatabase.FormatAndEscapeDatetimeValue(dateTimeList),...
                repmat([''',''' MySQLDatabase.Escape(fromTimezone) ''','],sz1,1),...
                repmat(['''' MySQLDatabase.Escape(toTimezone) ''')'],sz1,1)];
            wmat = wmat';
            queryString = wmat(:)';
            queryString(1:length(' UNION ALL ')) = ' ';
            queryString(end+1) = ';';
        end
    end
    methods (Static)
        function classNameString = ClassName()
            classNameString = mfilename;
        end
    end
end