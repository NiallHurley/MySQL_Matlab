classdef CachedTimeZoneConverter < TimeZoneConverter
    % CachedTimeZoneConverter
    % 
    % Like TimeZoneConverter but previously converted datetimes are cached
    % i.e. offers speedup when the same conversions are being called over and over
    
    properties %(Access = private)
       cache
    end
    
%   myMap = containers.Map(KEYS, VALUES)
% 
%     To extract a value from a Map:
%         myValue = myMap(key);   
%  
%     To modify existing key-value pairs in a Map:
%         myMap(key) = newValue;       %Set existing key to a new value.
%  
%     To add new key-value pairs to a Map:
%         myMap(newKey) = newerValue;  

    methods
        function this = CachedTimeZoneConverter(mysqlconn)
            % constructor - call superclass constructor
            this = this@TimeZoneConverter(mysqlconn);
            this.cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function outDateTimes = Convert(this,inDateTimes,fromTimezone, toTimezone)
            convertedDatetimeValues = nan(size(inDateTimes));
            conversionKeyName = [fromTimezone ':' toTimezone];
            
            cacheKeyExists = this.cache.isKey(conversionKeyName);

            % retrieve previously converted values
            if cacheKeyExists
                prevConvertedDatetimeMap = this.cache(conversionKeyName);
                for i = 1:length(inDateTimes)
                    if prevConvertedDatetimeMap.isKey(inDateTimes(i))
                        convertedDatetimeValues(i) = prevConvertedDatetimeMap(inDateTimes(i));
                    end
                end
            end
            
            % identify new values and convert them
            newDateTimesIndices = isnan(convertedDatetimeValues);
            newInDateTimes = inDateTimes(newDateTimesIndices);
            
            if isempty(newInDateTimes)
                outDateTimes = convertedDatetimeValues;
            else
                % if not found - call subclass method
                freshlyConvertedDateTimes = Convert@TimeZoneConverter(this,newInDateTimes,fromTimezone, toTimezone);
                               
                keys= newInDateTimes(:);
                values = freshlyConvertedDateTimes(:);
                newConvertedDatetimeMap = containers.Map(keys,values);
                                
                 % store the freshly converted values
                 
                if ~cacheKeyExists
                    updatedConvertedDatetimeMap = newConvertedDatetimeMap;
                else
                    updatedConvertedDatetimeMap = [ this.cache(conversionKeyName); newConvertedDatetimeMap];
                end
                this.cache(conversionKeyName) = updatedConvertedDatetimeMap;
                
                
                outDateTimes = convertedDatetimeValues;
                outDateTimes(newDateTimesIndices) = freshlyConvertedDateTimes;
            end
            assert(all(~isnan(outDateTimes)),'outdatetimes should have no NaNs');
        end
    end
    
end