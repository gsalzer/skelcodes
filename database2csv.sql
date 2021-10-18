-- skelcodes: materialized view with one deployed code per skeleton
--
-- If there are several deployed contracts for a skeleton,
-- we prefer deployments where the code hasn't yet self-destructed
-- and among these, those with a verified source on etherscan.io.
-- We do not consider codes with skeleton 0 (= empty string),
-- resulting e.g. from mayflies.
--
-- cdate: block-id/tx-id/msg-id of message creating the contract
-- aid: internal account id
-- code:  internal bytecode id
-- skeleton: internal id of skeleton
-- first: block-id/tx-id/msg-id of first deployed contract with this skeleton
-- last: block-id/tx-id/msg-id of last deployed contract with this skeleton
-- codes: number of different codes with this skeleton
-- contracts: total number of deployed contracts with this skeleton
create materialized view skelcode as (
with ranked as (
         select
                cdate,
                aid,
                code,
                skeleton,
                row_number() OVER (
                        PARTITION BY skeleton
                        ORDER BY (death is null) DESC, (sol is null) ASC, (cdate).bid ASC
                ) rank
        from
                contract2
                join code2 on code=cdeployed
                natural left join esverifiedcontract
        where
                skeleton <> 0
                and (cdate).bid < 13400000
),
top as (
        select cdate,aid,code,skeleton from ranked where rank=1
)
select top.cdate, top.aid, top.code, top.skeleton, msg_time_mins(contract2.cdate) "first", msg_time_maxs(contract2.cdate) "last", count(distinct cdeployed) codes, count(*) contracts
from
        top
       	join code2 on code2.skeleton=top.skeleton
       	join contract2 on contract2.cdeployed=code2.code
group by top.cdate, top.aid, top.code, top.skeleton
order by "first"
);
-- 226148
create index skelcodes_cdate_index on skelcodes(cdate);

\copy (select fork.bid fork,account(aid),bindata(code) code from skelcodes join fork on ("first").bid between fork.bid and fork.lastbid) to 'codes.csv' with csv;

\copy (select (cdate).bid block, (cdate).tid tx, (cdate).mid msg, account(aid) address, ("first").bid "first", ("last").bid "last", codes, contracts from skelcodes order by cdate) to 'info.csv' with csv header;
