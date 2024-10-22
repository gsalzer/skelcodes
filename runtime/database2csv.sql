-- skelcodes: materialized view with one deployed code per skeleton
--
-- If there are several deployed contracts for a skeleton,
-- we prefer deployments where the code hasn't yet self-destructed
-- and among these, those with a verified source on etherscan.io.
-- We do not consider codes with skeleton 0 (= empty string),
-- resulting e.g. from self-destructing deployment code.
-- This selection strategy is not reproducible, as new sources
-- arrive and contracts self-destruct. Moreover, the skelcodes
-- were initially retrieved for the block range 0-13499999,
-- and later were conservatively extended for 13500000-13999999.
--
-- cdate: block-id/tx-id/msg-id of message creating the contract
-- aid: internal account id
-- code:  internal bytecode id
-- skeleton: internal id of skeleton
-- first: block-id/tx-id/msg-id of first deployed contract with this skeleton
-- last: block-id/tx-id/msg-id of last deployed contract with this skeleton
-- codes: number of different codes with this skeleton
-- contracts: total number of deployed contracts with this skeleton
create table skelcode as 
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
                and (contract2.cdate).bid < 14000000
),
top as (
        select cdate,aid,code,skeleton from ranked where rank=1
)
select
	top.cdate,
	top.aid,
	top.code,
	top.skeleton,
	ct.len_code,
	ct.len_code1,
	array_length(ct.signatures,1) len_sigs,
	msg_time_mins(contract2.cdate) "first",
       	msg_time_maxs(contract2.cdate) "last",
       	count(distinct contract2.cdeployed) codes,
       	count(*) contracts
from
        top
       	join code2 c on c.skeleton=top.skeleton
       	join contract2 on contract2.cdeployed=c.code
	join code2 ct on ct.code=top.code
group by top.cdate, top.aid, top.code, top.skeleton, ct.len_code, ct.len_code1, len_sigs
order by top.cdate;
-- 248328
-- check possible combination of fields as key
-- create unique index skelcodes_aid_index on skelcode(aid); -- fails
create unique index skelcode_bid_aid_index on skelcode(((cdate).bid),aid); -- succeeds
create unique index skelcode_skeleton on skelcode(skeleton);

\copy (select (cdate).bid,account(aid),bindata(code) code from skelcode) to 'runtime.csv' with csv;

\copy (select (skelcode.cdate).bid,account(skelcode.aid),bindata(cdeployment) code from skelcode join contract2 on skelcode.cdate=contract2.cdate) to 'deployment.csv' with csv

\copy (select concat((cdate).bid,'-',account(aid),'.hex') filename,(cdate).bid block, (cdate).tid tx, (cdate).mid msg, account(aid) address, ("first").bid "first", ("last").bid "last", codes, contracts, len_code, len_code1, len_sigs from skelcode order by filename) to 'info.csv' with csv header;
