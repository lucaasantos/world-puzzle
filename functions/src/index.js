import {initializeApp} from 'firebase-admin/app';
import {getFirestore, Timestamp} from 'firebase-admin/firestore';
import {onCall, onRequest, HttpsError} from 'firebase-functions/v2/https';
import {randomUUID} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {economyConfig} from './config.js';
import {blocksLimits, dailyCycle, dailyDifficulty, difficulties, explorationScore, explorationTier, jigsawLimits, levelFor, normalizeWorldCoinEconomy, regenerate, shuffledBoard, verifyBlocksSolution, verifyJigsawSolution, verifySolution, weeklyCycle, weighted, packTypes} from './economy.js';
import {verifyAdCallback} from './ssv.js';

initializeApp();
const db = getFirestore();
const catalog = JSON.parse(readFileSync(new URL('./catalog.json', import.meta.url)));
const options = {region: 'southamerica-east1', enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true', maxInstances: 10};
const fail = (code, message) => { throw new HttpsError(code, message); };
const id = value => { if (typeof value !== 'string' || !/^[a-zA-Z0-9_-]{1,128}$/.test(value)) fail('invalid-argument','Identificador inválido.'); return value; };
const userRef = uid => db.doc(`users/${uid}`);
const sub = (uid, collection, key) => userRef(uid).collection(collection).doc(key);
const requireUser = snap => { if(!snap.exists) fail('failed-precondition','Crie seu perfil primeiro.'); return snap.data(); };
function callable(action) {
  return onCall(options, async request => {
    if (!request.auth) fail('unauthenticated', 'Entre para continuar.');
    if(process.env.FUNCTIONS_EMULATOR !== 'true' && request.auth.token.firebase?.sign_in_provider === 'anonymous') fail('permission-denied','Conta autenticada necessária.');
    return action(request.auth.uid, request.data ?? {}, await economyConfig());
  });
}
function view(user, config) { return {...user, progression: levelFor(user.totalXp, config)}; }
const dailyCountryPool = ['brazil', 'japan', 'egypt', 'greece'];
const dailyCountryIds = config => dailyCountryPool.slice(0, config.requiredCountries);
function newDaily(cycleId, config) {
  return {id:cycleId,countryIds:dailyCountryIds(config),countries:{},bestScore:0,claimed:false,config};
}
function normalizeDaily(daily, config) {
  const countryIds=dailyCountryIds(config);
  const countries={};
  for(const [countryId,value] of Object.entries(daily.countries ?? {})) {
    if(!countryIds.includes(countryId)) continue;
    const bestDifficulty=dailyDifficulty(value);
    if(!difficulties[bestDifficulty]) continue;
    countries[countryId]={completed:true,bestDifficulty,bestPoints:config.dailyPoints[bestDifficulty]};
  }
  return {...daily,countryIds,countries,bestScore:explorationScore(countries,config),config};
}
function newWeekly(weekId) {
  return {id:weekId,stages:{},totalStars:0,stagesCompleted:0};
}
function worldCoinView(user, cycleId, config) {
  return {...user,...normalizeWorldCoinEconomy(user,cycleId,config)};
}

export const createProfile = callable(async (uid, data, config) => {
  const nickname = typeof data.nickname === 'string' ? data.nickname.trim() : '';
  if(!/^[a-zA-Z0-9_]{3,18}$/.test(nickname)) fail('invalid-argument','Use de 3 a 18 letras, números ou _.');
  if(!['globe','compass','mountain','plane'].includes(data.avatar)) fail('invalid-argument','Avatar inválido.');
  const now = Date.now(), nicknameRef = db.doc(`nicknames/${nickname.toLowerCase()}`);
  await db.runTransaction(async tx => {
    const [existing, reserved] = await tx.getAll(userRef(uid), nicknameRef);
    if(existing.exists) return;
    if(reserved.exists) fail('already-exists','Este nickname já está em uso.');
    tx.create(nicknameRef,{uid});
    tx.create(db.doc(`profiles/${uid}`),{nickname,avatar:data.avatar,badges:[],achievements:[],profileFrame:null});
    tx.create(userRef(uid),{nickname,avatar:data.avatar,totalXp:0,starDustBalance:0,worldCoins:0,worldCoinRewardAds:{cycleId:dailyCycle(now,config).id,earnedToday:0},lives:config.lives.maximum,lifeAnchor:now,puzzlesCompleted:0,countriesExplored:[],cardsReceived:0,createdAt:now,activeAttempt:null});
  });
  return {created:true};
});

export const syncPlayer = callable(async (uid, data, config) => {
  const now=Date.now(), cycle=dailyCycle(now,config), week=weeklyCycle(now,config);
  return db.runTransaction(async tx => {
    const [snap, daily, weekly] = await tx.getAll(userRef(uid),sub(uid,'dailyExploration',cycle.id),sub(uid,'weeklyStarProgress',week.id));
    if(!snap.exists) return {needsProfile:true,serverNow:now,config};
    const previous=snap.data(), user=worldCoinView({...previous,...regenerate(previous,now,config)},cycle.id,config);
    tx.update(userRef(uid),{lives:user.lives,lifeAnchor:user.lifeAnchor,worldCoins:user.worldCoins,worldCoinRewardAds:user.worldCoinRewardAds});
    return {user:view({...user,starDustBalance:Math.min(config.starDustMaximum,user.starDustBalance??0)},config),daily:daily.exists?normalizeDaily(daily.data(),config):newDaily(cycle.id,config),weeklyStars:weekly.exists?weekly.data():newWeekly(week.id),serverNow:now,resetsAt:cycle.resetsAt,weeklyResetsAt:week.resetsAt,config,regenerated:user.lives-previous.lives};
  });
});

export const startAttempt = callable(async (uid,data,config) => {
  const requestId=id(data.requestId), country=id(data.countryId), level=id(data.levelId), difficulty=id(data.difficulty);
  const gameMode=data.gameMode;
  const validLevel=catalog.countries[country]?.includes(level);
  const validModeLevel=gameMode==='sliding'?!level.startsWith('jigsaw_')&&!level.startsWith('blocks_'):
    gameMode==='jigsaw'?level===`jigsaw_${country}_${difficulty}`:
    gameMode==='blocks'&&level===`blocks_${country}_${difficulty}`;
  if(!validLevel || !difficulties[difficulty] || !validModeLevel) fail('invalid-argument','Fase inválida.');
  const now=Date.now(), grid=gameMode==='blocks'?10:difficulties[difficulty].grid;
  const attempt={id:requestId,countryId:country,levelId:level,difficulty,gameMode,grid,board:gameMode==='sliding'?shuffledBoard(grid):null,startedAt:now,expiresAt:now+config.attemptTtlMs,state:'active',config};
  return db.runTransaction(async tx => {
    const [u,existing]=await tx.getAll(userRef(uid),sub(uid,'attempts',requestId));
    const user=requireUser(u);
    if(existing.exists) {
      const a=existing.data();
      if(a.countryId!==country || a.levelId!==level || a.difficulty!==difficulty || a.gameMode!==gameMode) fail('invalid-argument','Tentativa incompatível.');
      return a;
    }
    const life=regenerate(user,now,config);
    if(life.lives<config.lives.cost) fail('resource-exhausted','Suas vidas acabaram.');
    // Starting another board atomically abandons the previous attempt, even across devices.
    if(user.activeAttempt) tx.update(sub(uid,'attempts',user.activeAttempt),{state:'abandoned'});
    tx.update(userRef(uid),{...life,lives:life.lives-config.lives.cost,activeAttempt:requestId});
    tx.create(sub(uid,'attempts',requestId),attempt);
    return attempt;
  });
});

export const finishAttempt = callable(async (uid,data,config) => {
  const attemptId=id(data.attemptId), now=Date.now(), cycle=dailyCycle(now,config), week=weeklyCycle(now,config);
  return db.runTransaction(async tx => {
    const weeklyRef=sub(uid,'weeklyStarProgress',week.id);
    const [us,as,ds,ws]=await tx.getAll(userRef(uid),sub(uid,'attempts',attemptId),sub(uid,'dailyExploration',cycle.id),weeklyRef);
    const user=requireUser(us), attempt=as.data();
    if(!attempt) fail('not-found','Tentativa não encontrada.');
    if(attempt.state==='completed') return attempt.result;
    if(attempt.state!=='active' || user.activeAttempt!==attemptId) fail('failed-precondition','Tentativa encerrada.');
    try {
      if(attempt.gameMode==='jigsaw') verifyJigsawSolution(attempt,data.placements,data.moveCount,now);
      else if(attempt.gameMode==='blocks') verifyBlocksSolution(attempt,data.blocksLines,data.blocksScore,data.moveCount,now);
      else verifySolution(attempt,data.moves,now);
    } catch(error) { fail('invalid-argument',error.message); }
    const progressRef=sub(uid,'progress',attempt.levelId), ps=await tx.get(progressRef);
    const old=ps.data(), elapsed=Math.max(1,Math.floor((now-attempt.startedAt)/1000));
    const moveCount=attempt.gameMode==='blocks'||attempt.gameMode==='jigsaw'?data.moveCount:data.moves.length;
    const limits=attempt.gameMode==='blocks'?blocksLimits[attempt.difficulty]:attempt.gameMode==='jigsaw'?jigsawLimits[attempt.difficulty]:difficulties[attempt.difficulty];
    const stars=attempt.gameMode==='blocks'
      ? data.blocksScore>=limits.threeScore&&elapsed<=limits.threeSeconds?3:data.blocksScore>=limits.twoScore&&elapsed<=limits.twoSeconds?2:1
      : attempt.gameMode==='jigsaw'
      ? moveCount<=limits.threeMoves&&elapsed<=limits.threeSeconds?3:moveCount<=limits.twoMoves&&elapsed<=limits.twoSeconds?2:moveCount<=limits.oneMoves&&elapsed<=limits.oneSeconds?1:0
      : moveCount<=limits.moves*.6&&elapsed<=limits.seconds*.7?3:moveCount<=limits.moves*.8&&elapsed<=limits.seconds*.9?2:1;
    const score=attempt.gameMode==='blocks'?data.blocksScore:Math.max(0,attempt.grid*attempt.grid*1000-elapsed*2-moveCount*10);
    const weekly=ws.exists?ws.data():newWeekly(week.id);
    weekly.stages=weekly.stages??{};
    const weeklyKey=`${attempt.gameMode}:${attempt.countryId}:${attempt.levelId}`;
    const previousWeeklyStars=weekly.stages[weeklyKey]??0;
    const weeklyImprovement=Math.max(0,stars-previousWeeklyStars);
    if(stars>previousWeeklyStars) weekly.stages[weeklyKey]=stars;
    weekly.totalStars=Object.values(weekly.stages).reduce((sum,value)=>sum+value,0);
    weekly.stagesCompleted=Object.keys(weekly.stages).length;
    const starDustBefore=Math.min(config.starDustMaximum,user.starDustBalance??0);
    const starDustEarned=Math.min(weeklyImprovement,config.starDustMaximum-starDustBefore);
    const starDustBalance=starDustBefore+starDustEarned;
    const before=levelFor(user.totalXp,config), totalXp=user.totalXp+attempt.config.xp[attempt.difficulty], after=levelFor(totalXp,config);
    const daily=normalizeDaily(ds.exists?ds.data():newDaily(cycle.id,config),config);
    const previousScore=daily.bestScore;
    const previous=daily.countries[attempt.countryId];
    const previousPoints=previous?.bestPoints ?? 0;
    const attemptPoints=config.dailyPoints[attempt.difficulty];
    if(daily.countryIds.includes(attempt.countryId) && attemptPoints>previousPoints) {
      daily.countries[attempt.countryId]={completed:true,bestDifficulty:attempt.difficulty,bestPoints:attemptPoints};
    }
    daily.bestScore=explorationScore(daily.countries,config);
    const dailyPointsEarned=daily.bestScore-previousScore;
    const milestones=config.milestones.filter(m=>m.enabled && m.level>before.level && m.level<=after.level);
    const receipts = milestones.length ? await tx.getAll(...milestones.map(m=>sub(uid,'rewards',`level_${m.level}`))) : [];
    for(let i=0;i<milestones.length;i++) {
      if(receipts[i].exists) continue;
      const m=milestones[i], key=`level_${m.level}`;
      tx.create(sub(uid,'rewards',key),{type:'level',level:m.level,packType:m.packType,at:now});
      tx.create(sub(uid,'packs',key),{packType:m.packType,opened:false,earnedAt:now});
    }
    const result={xp:attempt.config.xp[attempt.difficulty],level:after.level,levelUp:after.level>before.level,stars,score,elapsedSeconds:elapsed,dailyId:cycle.id,dailyProgress:Object.keys(daily.countries).length,dailyScore:daily.bestScore,dailyPreviousScore:previousScore,dailyPointsEarned,explorationReady:!daily.claimed&&daily.bestScore>=config.dailyRewardMilestones[0],starDustEarned,starDustPotential:weeklyImprovement,starDustBefore,starDustBalance,starDustFull:starDustBalance>=config.starDustMaximum,weeklyBestStars:weekly.stages[weeklyKey],newWeeklyRecord:stars>previousWeeklyStars,isNewRecord:!old || elapsed<old.bestTimeSeconds || moveCount<old.bestMoves || score>(old.bestScore??0)};
    tx.update(userRef(uid),{totalXp,starDustBalance,puzzlesCompleted:user.puzzlesCompleted+1,countriesExplored:[...new Set([...user.countriesExplored,attempt.countryId])],activeAttempt:null});
    tx.update(sub(uid,'attempts',attemptId),{state:'completed',completedAt:now,result});
    tx.set(progressRef,{levelId:attempt.levelId,gameMode:attempt.gameMode,difficulty:attempt.difficulty,bestTimeSeconds:Math.min(old?.bestTimeSeconds??elapsed,elapsed),bestMoves:Math.min(old?.bestMoves??moveCount,moveCount),bestScore:Math.max(old?.bestScore??0,score),stars:Math.max(old?.stars??0,stars),completions:(old?.completions??0)+1,firstCompletedAt:old?.firstCompletedAt??new Date(now).toISOString(),bestResultAt:new Date(now).toISOString()});
    tx.set(sub(uid,'dailyExploration',cycle.id),daily);
    tx.set(weeklyRef,weekly);
    return result;
  });
});

export const spendStarDust = callable(async(uid,data,config) => {
  const requestId=id(data.requestId), amount=data.amount;
  if(!Number.isInteger(amount) || amount<1 || amount>config.starDustMaximum) fail('invalid-argument','Quantidade inválida.');
  const receipt=sub(uid,'starDustTransactions',requestId), now=Date.now();
  return db.runTransaction(async tx=>{
    const [us,rs]=await tx.getAll(userRef(uid),receipt);
    const user=requireUser(us);
    if(rs.exists) return rs.data();
    const balance=Math.min(config.starDustMaximum,user.starDustBalance??0);
    if(balance<amount) fail('failed-precondition','Pó Estelar insuficiente.');
    const result={id:requestId,amount,balance:balance-amount,at:now};
    tx.update(userRef(uid),{starDustBalance:result.balance});
    tx.create(receipt,result);
    return result;
  });
});

export const endAttempt = callable(async(uid,data) => {
  const key=id(data.attemptId), reason=data.reason==='failed'?'failed':'abandoned';
  await db.runTransaction(async tx=>{
    const [us,as]=await tx.getAll(userRef(uid),sub(uid,'attempts',key));
    const u=requireUser(us);
    if(as.data()?.state!=='active') return;
    tx.update(sub(uid,'attempts',key),{state:reason});
    if(u.activeAttempt===key) tx.update(userRef(uid),{activeAttempt:null});
  });
  return {ended:true};
});

export const claimExploration = callable(async(uid,data,config) => {
  const day=id(data.dailyId), now=Date.now();
  return db.runTransaction(async tx=>{
    const [us,ds,rs]=await tx.getAll(userRef(uid),sub(uid,'dailyExploration',day),sub(uid,'rewards',`daily_${day}`));
    requireUser(us);
    if(rs.exists) return rs.data();
    if(!ds.exists || ds.data().claimed) fail('failed-precondition','Exploração indisponível.');
    const daily=normalizeDaily(ds.data(),config);
    if(Object.keys(daily.countries).some(c=>!catalog.countries[c])) fail('failed-precondition','País inválido.');
    let tier;
    try { tier=explorationTier(daily.countries,config); } catch { fail('failed-precondition','Complete quatro países diferentes.'); }
    const packType=packTypes[weighted(config.packOdds[tier-1])], key=`daily_${day}`;
    const reward={id:key,packType,tier,score:daily.bestScore,dailyId:day,at:now};
    tx.create(sub(uid,'rewards',key),reward);
    tx.create(sub(uid,'packs',key),{packType,opened:false,earnedAt:now});
    tx.update(sub(uid,'dailyExploration',day),{countries:daily.countries,bestScore:daily.bestScore,claimed:true,tier,packType});
    return reward;
  });
});

export const openPack = callable(async(uid,data) => {
  const key=id(data.packInstanceId), now=Date.now();
  return db.runTransaction(async tx=>{
    const [us,ps]=await tx.getAll(userRef(uid),sub(uid,'packs',key));
    const user=requireUser(us), pack=ps.data();
    if(!pack) fail('not-found','Pacote não encontrado.');
    if(pack.opened) return pack.result;
    const definition=catalog.packs[pack.packType];
    if(!definition) fail('failed-precondition','Pacote indisponível.');
    const rarities=Object.keys(definition.weights).filter(r=>catalog.cards.some(c=>c.rarity===r));
    const cards=Array.from({length:definition.count},()=>{
      const rarity=rarities[weighted(rarities.map(r=>definition.weights[r]))];
      const pool=catalog.cards.filter(c=>c.rarity===rarity);
      return pool[weighted(pool.map(()=>1))];
    });
    const unique=[...new Set(cards.map(c=>c.id))];
    const inventory=await tx.getAll(...unique.map(c=>sub(uid,'collection',c)));
    const entries=Object.fromEntries(inventory.map((s,i)=>[unique[i],s.data()??{cardId:unique[i],quantity:0,pastedInAlbum:false}]));
    const rewards=cards.map(c=>{
      const e=entries[c.id], isNew=e.quantity===0&&!e.pastedInAlbum;
      e.quantity++;
      return {cardId:c.id,isNew,resultingQuantity:e.quantity,wasAlreadyPasted:e.pastedInAlbum,rarity:c.rarity};
    });
    for(const c of unique) tx.set(sub(uid,'collection',c),entries[c]);
    const result={packId:pack.packType,cards:rewards};
    tx.update(sub(uid,'packs',key),{opened:true,openedAt:now,result});
    tx.update(userRef(uid),{cardsReceived:user.cardsReceived+cards.length});
    return result;
  });
});

export const debugGrantPack = callable(async(uid,data) => {
  const packType=id(data.packType), quantity=data.quantity;
  if(!packTypes.includes(packType) || !Number.isInteger(quantity) || quantity<1 || quantity>10) {
    fail('invalid-argument','Pacote ou quantidade inválida.');
  }
  const user=requireUser(await userRef(uid).get());
  if(user.debugToolsEnabled!==true) {
    fail('permission-denied','Ferramentas de teste não habilitadas para esta conta.');
  }
  const batch=db.batch(), now=Date.now();
  for(let index=0;index<quantity;index++) {
    const key=`debug_${now}_${randomUUID()}`;
    batch.create(sub(uid,'packs',key),{packType,opened:false,earnedAt:now,debug:true});
  }
  await batch.commit();
  return {packType,quantity};
});

export const pasteCard = callable(async(uid,data)=>{
  const card=id(data.cardId);
  if(!catalog.cards.some(c=>c.id===card)) fail('not-found','Carta inválida.');
  return db.runTransaction(async tx=>{
    const entry=await tx.get(sub(uid,'collection',card)), current=entry.data();
    if(current?.pastedInAlbum) return {pasted:true};
    if(!current || current.quantity<1) fail('failed-precondition','Nenhuma cópia disponível.');
    tx.update(sub(uid,'collection',card),{quantity:current.quantity-1,pastedInAlbum:true});
    tx.create(sub(uid,'album',card),{cardId:card,placedAt:Date.now()});
    return {pasted:true};
  });
});

export const prepareLifeAd = callable(async(uid,data,config)=>{
  const now=Date.now();
  return db.runTransaction(async tx=>{
    const snap=await tx.get(userRef(uid)), user=requireUser(snap);
    if(user.lastAdTicketAt && now-user.lastAdTicketAt<30000) fail('resource-exhausted','Aguarde antes de tentar novamente.');
    if(regenerate(user,now,config).lives>=config.lives.maximum) fail('failed-precondition','Vidas completas.');
    const key=randomUUID();
    tx.create(sub(uid,'adTickets',key),{createdAt:now,expiresAt:now+3600000,redeemed:false,amount:config.lives.rewarded});
    tx.update(userRef(uid),{lastAdTicketAt:now});
    return {ticket:key};
  });
});

export const prepareWorldCoinAd = callable(async(uid,data,config)=>{
  const now=Date.now(), cycle=dailyCycle(now,config);
  return db.runTransaction(async tx=>{
    const snap=await tx.get(userRef(uid)), user=requireUser(snap);
    const economy=normalizeWorldCoinEconomy(user,cycle.id,config);
    if(economy.worldCoinRewardAds.earnedToday>=config.worldCoin.dailyAdLimit) {
      fail('resource-exhausted','Limite diário de World Coins atingido.');
    }
    if(user.lastWorldCoinAdTicketAt && now-user.lastWorldCoinAdTicketAt<3000) {
      fail('resource-exhausted','Aguarde antes de tentar novamente.');
    }
    const key=randomUUID();
    tx.create(sub(uid,'adTickets',key),{
      kind:'world_coin',createdAt:now,expiresAt:now+3600000,redeemed:false,
      rewardAmount:config.worldCoin.rewardedAdAmount,cycleId:cycle.id,
    });
    tx.update(userRef(uid),{
      ...economy,lastWorldCoinAdTicketAt:now,
    });
    return {
      ticket:key,balance:economy.worldCoins,
      earnedToday:economy.worldCoinRewardAds.earnedToday,
      dailyLimit:config.worldCoin.dailyAdLimit,
      rewardAmount:config.worldCoin.rewardedAdAmount,
    };
  });
});

function creditWorldCoin(tx,{uid,user,ticket,ticketRef,receiptRef,transaction,now,config}) {
  if(!ticket || ticket.kind!=='world_coin' || ticket.redeemed || now>ticket.expiresAt) {
    fail('permission-denied','Ticket de recompensa inválido.');
  }
  const cycle=dailyCycle(now,config), economy=normalizeWorldCoinEconomy(user,cycle.id,config);
  if(economy.worldCoinRewardAds.earnedToday>=config.worldCoin.dailyAdLimit) {
    fail('resource-exhausted','Limite diário de World Coins atingido.');
  }
  const amount=config.worldCoin.rewardedAdAmount;
  if(economy.worldCoins>Number.MAX_SAFE_INTEGER-amount) fail('failed-precondition','Saldo inválido.');
  const result={
    status:'granted',transactionId:transaction,currency:'world_coin',
    amount,balance:economy.worldCoins+amount,
    earnedToday:economy.worldCoinRewardAds.earnedToday+1,
    dailyLimit:config.worldCoin.dailyAdLimit,cycleId:cycle.id,
  };
  tx.update(userRef(uid),{
    worldCoins:result.balance,
    worldCoinRewardAds:{cycleId:cycle.id,earnedToday:result.earnedToday},
  });
  tx.update(ticketRef,{redeemed:true,transaction,result,redeemedAt:now});
  tx.create(receiptRef,{uid,ticket:ticketRef.id,kind:'world_coin',at:now});
  tx.create(sub(uid,'economyTransactions',transaction),{
    transactionId:transaction,userId:uid,currency:'world_coin',type:'rewarded_ad',
    amount,balanceAfter:result.balance,createdAt:Timestamp.fromMillis(now),
    source:'world_coin_rewarded_ad',metadata:{ticketId:ticketRef.id,cycleId:cycle.id},
  });
  return result;
}

// In production this callable only observes the signed SSV result. The emulator
// completes the same transaction so the full client flow can be tested locally.
export const claimRewardedWorldCoin = callable(async(uid,data,config)=>{
  const ticketId=id(data.ticket), ticketRef=sub(uid,'adTickets',ticketId), now=Date.now();
  return db.runTransaction(async tx=>{
    const [us,ts]=await tx.getAll(userRef(uid),ticketRef);
    const user=requireUser(us), ticket=ts.data();
    if(!ticket || ticket.kind!=='world_coin') fail('not-found','Recompensa não encontrada.');
    if(ticket.redeemed) return ticket.result;
    if(process.env.FUNCTIONS_EMULATOR!=='true') {
      return {status:'pending'};
    }
    const transaction=`emulator_${ticketId}`, receiptRef=db.doc(`adTransactions/${transaction}`);
    const receipt=await tx.get(receiptRef);
    if(receipt.exists) return ticket.result??{status:'pending'};
    return creditWorldCoin(tx,{uid,user,ticket,ticketRef,receiptRef,transaction,now,config});
  });
});

// Only signed AdMob SSV requests may grant lives. Client callbacks cannot do so.
export const admobReward = onRequest({region:options.region,maxInstances:10},async(req,res)=>{
  try {
    const p=await verifyAdCallback(req.originalUrl,process.env.ADMOB_REWARDED_UNIT_IDS??'');
    const uid=id(p.user_id), ticket=id(p.custom_data), transaction=id(p.transaction_id), now=Date.now(), config=await economyConfig();
    await db.runTransaction(async tx=>{
      const receipt=db.doc(`adTransactions/${transaction}`);
      const ticketRef=sub(uid,'adTickets',ticket);
      const [us,ts,rs]=await tx.getAll(userRef(uid),ticketRef,receipt);
      if(rs.exists) return;
      const u=requireUser(us), t=ts.data();
      if(!t || t.redeemed || Number(p.timestamp)<t.createdAt || Number(p.timestamp)>t.expiresAt) fail('permission-denied','Invalid ticket');
      if(t.kind==='world_coin') {
        creditWorldCoin(tx,{uid,user:u,ticket:t,ticketRef,receiptRef:receipt,transaction,now,config});
      } else {
        const life=regenerate(u,now,config);
        tx.update(userRef(uid),{...life,lives:Math.min(config.lives.maximum,life.lives+t.amount)});
        tx.update(ticketRef,{redeemed:true,transaction});
        tx.create(receipt,{uid,ticket,kind:'life',at:now});
      }
    });
    res.status(200).send('OK');
  } catch(error) { res.status(error.code==='unavailable'?503:403).send('Reward verification failed'); }
});
