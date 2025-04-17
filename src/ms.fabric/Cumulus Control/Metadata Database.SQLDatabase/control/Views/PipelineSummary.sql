
CREATE view [control].[PipelineSummary]
as
with cte
as (
   select coalesce(ids.ComponentName, tds.ComponentName, 'Unassigned')          as ComponentName
        , coalesce(ids.DatasetId, tds.DatasetId, null)                          as DatasetId
        , coalesce(ids.DatasetDisplayName, tds.DatasetName, p.PipelineName)     as DatasetName
        , p.PipelineName                                                        as PipelineName
        , pp.ParameterName                                                      as ParameterName
        , pp.ParameterValue                                                     as ParameterValue
        , p.PipelineId                                                          as PipelineId
        , s.StageName                                                           as StageName
        , pd.DependantPipelineId                                                as DependantPipelineId
        , coalesce(p.Enabled & ids.Enabled, p.Enabled & tds.Enabled, p.Enabled) as Enabled
   from control.Pipelines                                               as p
       join control.PipelineParameters                                  as pp
           on p.PipelineId = pp.PipelineId
       join control.Stages                                              as s
           on p.StageId = s.StageId
       left join control.PipelineDependencies                           as pd
           on p.PipelineId = pd.PipelineId
       left join
       (select 'Ingest' as ComponentName, * from ingest.Datasets)       as ids
           on pp.ParameterValue = cast(ids.DatasetId as varchar(4))
              and p.PipelineName like 'Ingest_PL_%'
       left join
       (select 'Transform' as ComponentName, * from transform.Datasets) as tds
           on pp.ParameterValue = cast(tds.DatasetId as varchar(4))
              and p.PipelineName like 'Transform_PL_%'
--
)
select cte.ComponentName
     , cte.DatasetId
     , cte.DatasetName
     , cte.PipelineName
     , cte.ParameterName
     , cte.ParameterValue
     , cte.PipelineId
     , cte.StageName
     , cte.DependantPipelineId
     , cte.Enabled
     , cte2.DatasetName  as DependsOnDataset
     , cte2.PipelineName as DependsOnPipelineName
     , cte2.PipelineId   as DependsOnPipelineId
from cte
    left join cte as cte2
        on cte.PipelineId = cte2.DependantPipelineId;

GO

