--Metadata As Code - Add connections for demo environment

EXEC ##AddConnections 'Azure SQL Database', 'AdventureWorksDemo', '$(DemoConnectionLocation)', NULL, '$(DemoSourceLocation)', '$(DemoResourceName)', '$(DemoLinkedService)', '$(DemoUsername)', '$(DemoKVSecret)', 1;
