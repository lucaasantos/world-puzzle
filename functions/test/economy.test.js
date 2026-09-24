import {test} from 'node:test';
import assert from 'node:assert/strict';
import {generateKeyPairSync, sign} from 'node:crypto';
import {blocksLimits, defaults, validateConfig, levelFor, dailyCycle, weeklyCycle, normalizeWorldCoinEconomy, regenerate, explorationScore, explorationTier, weighted, shuffledBoard, verifyBlocksSolution, verifySolution} from '../src/economy.js';
import {verifyAdCallback} from '../src/ssv.js';

test('progressive levels preserve all XP above the cap',()=>{
  assert.equal(levelFor(0).level,1); assert.equal(levelFor(99).level,1); assert.equal(levelFor(100).level,2);
  assert.ok(levelFor(100).nextXp>100);
  assert.equal(levelFor(100000000).level,30); assert.equal(levelFor(100000000).totalXp,100000000); assert.equal(levelFor(100000000).nextXp,null);
  assert.equal(levelFor(100000000,{...defaults,levelCap:50}).level,50);
});
test('UTC reset boundary and regeneration use server time',()=>{
  const boundary=Date.parse('2026-09-16T03:00:00Z');
  assert.equal(dailyCycle(boundary-1).id,'2026-09-15'); assert.equal(dailyCycle(boundary).id,'2026-09-16');
  const start={lives:1,lifeAnchor:boundary};
  assert.equal(regenerate(start,boundary+1799999).lives,1);
  assert.equal(regenerate(start,boundary+1800000).lives,2);
  assert.equal(regenerate(start,boundary+86400000).lives,4);
  assert.equal(regenerate(start,boundary-500).lives,1);
  const sunday=Date.parse('2026-09-20T03:00:00Z');
  assert.equal(weeklyCycle(sunday-1).id,'2026-09-13');
  assert.equal(weeklyCycle(sunday).id,'2026-09-20');
  assert.equal(weeklyCycle(sunday).resetsAt,Date.parse('2026-09-27T03:00:00Z'));
});
test('World Coin defaults, migration, reset, integer safety and config are server-defined',()=>{
  const day='2026-09-21';
  assert.deepEqual(normalizeWorldCoinEconomy({},day),{worldCoins:0,worldCoinRewardAds:{cycleId:day,earnedToday:0}});
  assert.deepEqual(normalizeWorldCoinEconomy({worldCoins:12,worldCoinRewardAds:{cycleId:day,earnedToday:9}},day),{worldCoins:12,worldCoinRewardAds:{cycleId:day,earnedToday:9}});
  assert.equal(normalizeWorldCoinEconomy({worldCoins:-1,worldCoinRewardAds:{cycleId:'old',earnedToday:10}},day).worldCoins,0);
  assert.equal(normalizeWorldCoinEconomy({worldCoins:1.5,worldCoinRewardAds:{cycleId:day,earnedToday:1.5}},day).worldCoinRewardAds.earnedToday,0);
  assert.equal(defaults.worldCoin.rewardedAdAmount,1);
  assert.equal(defaults.worldCoin.dailyAdLimit,10);
  assert.throws(()=>validateConfig({...defaults,worldCoin:{rewardedAdAmount:1000,dailyAdLimit:10}}));
});
test('daily exploration derives best score and fixed reward milestones',()=>{
  const choices=['easy','medium','hard'];
  for(const a of choices)for(const b of choices)for(const c of choices)for(const d of choices){
    const values=[a,b,c,d], score=values.reduce((s,v)=>s+defaults.dailyPoints[v],0);
    const expected=score>=80?4:score>=70?3:score>=60?2:1;
    const countries=Object.fromEntries(values.map((v,i)=>[String(i),{completed:true,bestDifficulty:v,bestPoints:defaults.dailyPoints[v]}]));
    assert.equal(explorationScore(countries),score);
    assert.equal(explorationTier(countries),expected);
  }
  assert.equal(explorationScore({brazil:'easy',japan:{bestDifficulty:'hard'}}),30);
  assert.throws(()=>explorationTier({japan:'hard'}));
  assert.throws(()=>explorationTier({a:'easy',b:'easy',c:'easy',d:'hacked'}));
});
test('odds boundaries, bad config, and disabled milestones',()=>{
  assert.equal(weighted([70,25,4,1],()=>0),0);
  assert.equal(weighted([70,25,4,1],()=>.7),1);
  assert.equal(weighted([70,25,4,1],()=>.95),2);
  assert.equal(weighted([70,25,4,1],()=>.999),3);
  assert.equal(validateConfig(defaults),defaults);
  assert.throws(()=>validateConfig({...defaults,packOdds:[[1000,0,0,0]]}));
  assert.throws(()=>validateConfig({...defaults,lives:{...defaults.lives,cost:0}}));
  assert.ok(defaults.milestones.every(m=>!m.enabled));
});
test('server challenges have a valid permutation and reject forged solutions',()=>{
  for(const grid of [3,4,5]){
    const board=shuffledBoard(grid);
    assert.deepEqual([...board].sort((a,b)=>a-b),Array.from({length:grid*grid},(_,i)=>i));
    assert.ok(board.some((v,i)=>v!==i));
    const numbered=board.filter(v=>v!==grid*grid-1);
    let inversions=0;for(let i=0;i<numbered.length;i++)for(let j=i+1;j<numbered.length;j++)if(numbered[i]>numbered[j])inversions++;
    const rowFromBottom=grid-Math.floor(board.indexOf(grid*grid-1)/grid);
    assert.equal(grid%2?inversions%2:(inversions+rowFromBottom)%2,grid%2?0:1);
  }
  const a={board:[0,1,2,3,4,5,6,8,7],grid:3,difficulty:'easy',startedAt:0,expiresAt:100000,config:defaults};
  verifySolution(a,[8],5000);
  assert.throws(()=>verifySolution(a,[0],5000));
  assert.throws(()=>verifySolution(a,[],5000));
  assert.throws(()=>verifySolution(a,[8],10));
  assert.throws(()=>verifySolution(a,[8],100001));
  const blocks={difficulty:'easy',startedAt:0,expiresAt:100000,config:defaults};
  verifyBlocksSolution(blocks,blocksLimits.easy.targetLines,2400,8,5000);
  assert.throws(()=>verifyBlocksSolution(blocks,9,2400,8,5000));
  assert.throws(()=>verifyBlocksSolution(blocks,10,-1,8,5000));
  assert.throws(()=>verifyBlocksSolution(blocks,10,2400,1,5000));
});
test('SSV requires valid signature, unit, identity and unmodified query',async()=>{
  const {privateKey,publicKey}=generateKeyPairSync('ec',{namedCurve:'prime256v1'});
  const keys=async()=>[{keyId:7,pem:publicKey.export({type:'spki',format:'pem'})}];
  const query=`ad_unit=test_unit&custom_data=ticket&timestamp=${Date.now()}&transaction_id=txn&user_id=player`;
  const signature=sign('sha256',Buffer.from(query),privateKey).toString('base64url');
  const url=`/reward?${query}&signature=${signature}&key_id=7`;
  assert.equal((await verifyAdCallback(url,'test_unit',keys)).user_id,'player');
  await assert.rejects(verifyAdCallback(url.replace('player','intruder'),'test_unit',keys));
  await assert.rejects(verifyAdCallback(url,'other_unit',keys));
  await assert.rejects(verifyAdCallback(url.replace('&signature','&user_id=intruder&signature'),'test_unit',keys));
  await assert.rejects(verifyAdCallback('/reward?user_id=player','test_unit',keys));
});
