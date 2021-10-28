-- skelcodes: materialized view with one deployed code per skeleton
--
-- If there are several deployed contracts for a skeleton,
-- we prefer deployments where the code hasn't yet self-destructed
-- and among these, those with a verified source on etherscan.io.
-- We do not consider codes with skeleton 0 (= empty string),
-- resulting e.g. from self-destructing deployment code.
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
                contract2.cdate,
                contract2.aid,
                code2.code,
                code2.skeleton,
                row_number() OVER (
                        PARTITION BY code2.skeleton
                        ORDER BY
				(contract2.death is null) DESC,
				(es.sol is null) ASC,
			       	(contract2.cdate).bid ASC
                ) rank
        from
                contract2
                join code2 on code2.code = contract2.cdeployed
                left join esverifiedcontract es on es.aid = contract2.aid
        where
                code2.skeleton <> 0
                and (contract2.cdate).bid < 13500000
),
top as (
        select cdate,aid,code,skeleton from ranked where rank=1
)
select
	top.cdate,
	top.aid,
	top.code,
	top.skeleton,
	msg_time_mins(contract2.cdate) "first",
       	msg_time_maxs(contract2.cdate) "last",
       	count(distinct contract2.cdeployed) codes,
       	count(*) contracts
from
        top
       	join code2 on code2.skeleton=top.skeleton
       	join contract2 on contract2.cdeployed=code2.code
group by top.cdate, top.aid, top.code, top.skeleton
order by top.cdate
);
-- 229951
-- check possible combination of fields as key
-- create unique index skelcodes_aid_index on skelcode(aid); -- fails
create unique index skelcodes_bid_aid_index on skelcode(((cdate).bid),aid); -- succeed

\copy (select (cdate).bid,account(aid),bindata(code) code from skelcode) to 'codes.csv' with csv;

\copy (select (cdate).bid block, (cdate).tid tx, (cdate).mid msg, account(aid) address, ("first").bid "first", ("last").bid "last", codes, contracts from skelcode order by cdate) to 'info.csv' with csv header;
