function CachedTimeZoneConverterBench
hostName ='localhost';   %The database host
userName ='test_user';   %The userName for the database
password ='';
% % % useful for testing: p = MySQLDatabase(hostName,userName,password);
mysqlConn = MySQLDatabase(hostName,userName,password);

tzc = TimeZoneConverter(mysqlConn);
cachedTZC = CachedTimeZoneConverter(mysqlConn);


fromtz = 'Europe/Dublin';
totz = 'UTC';
disp(' n random sequential')
tic
N = 1000;
vals = now+rand(N,1);
for n = 1:N;
    tzc.Convert(vals(n),fromtz,totz);
end
disp(DateUtils.formatSecondsNice(toc));
tic
for n = 1:N;
    cachedTZC.Convert(vals(n),fromtz,totz);
end
disp(DateUtils.formatSecondsNice(toc));

% using cache
disp(' n random bulk')
tic
for i = 1:10
    out = tzc.Convert(vals,fromtz,totz);
end
disp(DateUtils.formatSecondsNice(toc));

cachedTZC = CachedTimeZoneConverter(mysqlConn);
tic
for i = 1:10
    out2 = cachedTZC.Convert(vals,fromtz,totz);
end
disp(DateUtils.formatSecondsNice(toc));
assert(isequal(out,out2));
end
