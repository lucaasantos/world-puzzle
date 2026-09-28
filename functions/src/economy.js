import {randomInt} from 'node:crypto';

export const defaults = {
  version: 1, levelCap: 30, xpBase: 100, xpGrowth: 35, xpPower: 1.5,
  xp: {easy: 25, medium: 50, hard: 90, veryHard: 130},
  lives: {maximum: 4, regenerationMs: 1800000, rewarded: 2, cost: 1, lossRule: 'on_start'},
  interstitialEvery: 3, resetHourUtc: 3, requiredCountries: 4,
  thresholds: [1.5, 2, 2.5],
  // Very Hard is deliberately isolated so Live Ops can rebalance it later.
  dailyPoints: {easy: 10, medium: 15, hard: 20, veryHard: 25},
  dailyRewardMilestones: [40, 60, 70, 80, 100],
  starDustMaximum: 100,
  worldCoin: {rewardedAdAmount: 1, dailyAdLimit: 10},
  // Firestore does not support arrays nested directly in arrays.
  packOdds: {0: [100, 0, 0, 0], 1: [95, 5, 0, 0], 2: [88, 8, 4, 0], 3: [85, 9, 5, 1], 4: [84, 9, 5, 2]},
  weeklyRewards: [
    {points: 300, packType: 'world_pack'},
    {points: 450, packType: 'explorer_pack'},
    {points: 600, packType: 'tier3_pack'},
    {points: 700, packType: 'tier4_pack'},
  ],
  milestones: [
    {level: 5, enabled: true, packType: 'world_pack', bonuses: {rare: 1}},
    {level: 10, enabled: true, packType: 'explorer_pack', bonuses: {epic: .5}},
    {level: 15, enabled: true, packType: 'world_pack', bonuses: {legendary: .2}},
    {level: 20, enabled: true, packType: 'tier3_pack', bonuses: {rare: 1}},
    {level: 25, enabled: true, packType: 'explorer_pack', bonuses: {epic: .5}},
    {level: 30, enabled: true, packType: 'tier4_pack', bonuses: {legendary: .3}},
  ],
  attemptTtlMs: 86400000, minCompletionMs: 3000, maxMoves: 20000,
};
export const difficulties = {easy: {grid: 3, points: 1, seconds: 900, moves: 700}, medium: {grid: 4, points: 2, seconds: 1200, moves: 1000}, hard: {grid: 5, points: 3, seconds: 1800, moves: 2000}, veryHard: {grid: 6, points: 4, seconds: 2400, moves: 3000}};
export const jigsawLimits = {
  easy: {oneSeconds: 360, oneMoves: 45, twoSeconds: 240, twoMoves: 28, threeSeconds: 150, threeMoves: 16},
  medium: {oneSeconds: 600, oneMoves: 85, twoSeconds: 420, twoMoves: 55, threeSeconds: 270, threeMoves: 32},
  hard: {oneSeconds: 900, oneMoves: 140, twoSeconds: 660, twoMoves: 90, threeSeconds: 450, threeMoves: 50},
  veryHard: {oneSeconds: 1200, oneMoves: 220, twoSeconds: 900, twoMoves: 145, threeSeconds: 600, threeMoves: 80},
};
export const blocksLimits = {
  easy: {targetLines: 10, twoScore: 1800, threeScore: 3200, twoSeconds: 600, threeSeconds: 420},
  medium: {targetLines: 20, twoScore: 5000, threeScore: 8500, twoSeconds: 900, threeSeconds: 660},
  hard: {targetLines: 30, twoScore: 9500, threeScore: 15000, twoSeconds: 1140, threeSeconds: 840},
  veryHard: {targetLines: 40, twoScore: 15000, threeScore: 23000, twoSeconds: 1380, threeSeconds: 1020},
};
export const packTypes = ['world_pack', 'explorer_pack', 'tier3_pack', 'tier4_pack'];
export const dailyCountryPool = ['brazil', 'japan', 'united_states', 'egypt'];
export function validateConfig(c) {
  const integer = (n, low, high) => Number.isInteger(n) && n >= low && n <= high;
  if (!integer(c.version, 1, 100000) || !integer(c.levelCap, 2, 100) || !integer(c.xpBase, 1, 100000) || !integer(c.xpGrowth, 1, 100000) || !(c.xpPower >= 1 && c.xpPower <= 3) ||
    !Object.keys(difficulties).every(k => integer(c.xp?.[k], 1, 10000)) ||
    !integer(c.lives?.maximum, 1, 20) || !integer(c.lives?.regenerationMs, 60000, 86400000) || !integer(c.lives?.rewarded, 1, 20) || !integer(c.lives?.cost, 1, c.lives.maximum) || c.lives.lossRule !== 'on_start' ||
    !integer(c.interstitialEvery, 0, 100) || !integer(c.resetHourUtc, 0, 23) || c.requiredCountries !== 4 ||
    !Array.isArray(c.thresholds) || c.thresholds.length !== 3 || !c.thresholds.every((n,i,a) => n > 1 && n <= 3 && (i === 0 || n > a[i-1])) ||
    Object.keys(c.dailyPoints ?? {}).join(',') !== 'easy,medium,hard,veryHard' || !Object.values(c.dailyPoints).every(n => integer(n, 1, 100)) ||
    !Array.isArray(c.dailyRewardMilestones) || c.dailyRewardMilestones.join(',') !== '40,60,70,80,100' ||
    c.starDustMaximum !== 100 ||
    !integer(c.worldCoin?.rewardedAdAmount, 1, 100) ||
    !integer(c.worldCoin?.dailyAdLimit, 1, 100) ||
    !c.packOdds || Array.isArray(c.packOdds) || Object.keys(c.packOdds).join(',') !== '0,1,2,3,4' || !Object.values(c.packOdds).every(row => Array.isArray(row) && row.length === 4 && row.every(n => Number.isFinite(n) && n >= 0) && Math.abs(row.reduce((a,b)=>a+b,0)-100)<0.001) ||
    !Array.isArray(c.weeklyRewards) || c.weeklyRewards.length !== 4 || !c.weeklyRewards.every((r,i,a) => integer(r.points,1,700) && packTypes.includes(r.packType) && (i === 0 || r.points > a[i-1].points)) || c.weeklyRewards[0].points !== 300 || c.weeklyRewards.at(-1).points !== 700 ||
    !Array.isArray(c.milestones) || c.milestones.length > 100 || !c.milestones.every(m => integer(m.level,2,c.levelCap) && typeof m.enabled === 'boolean' && (!m.enabled || packTypes.includes(m.packType)) && Object.entries(m.bonuses ?? {}).every(([rarity,value]) => ['rare','epic','legendary'].includes(rarity) && Number.isFinite(value) && value >= 0 && value <= 20)) ||
    !integer(c.attemptTtlMs, 60000, 172800000) || !integer(c.minCompletionMs, 1000, 60000) || !integer(c.maxMoves, 100, 20000)) throw new Error('Invalid economy configuration');
  return c;
}
export function levelFor(xp, c = defaults) {
  let level = 1, floor = 0, needed = c.xpBase;
  while (level < c.levelCap) {
    needed = Math.round(c.xpBase + c.xpGrowth * (level - 1) ** c.xpPower);
    if (xp < floor + needed) break;
    floor += needed; level++;
  }
  return {level, totalXp: xp, currentXp: xp - floor, nextXp: level === c.levelCap ? null : needed};
}
export function levelBonuses(level, c = defaults) {
  const bonuses={rare:0,epic:0,legendary:0};
  for(const milestone of c.milestones) {
    if(!milestone.enabled || milestone.level>level) continue;
    for(const rarity of Object.keys(bonuses)) bonuses[rarity]+=milestone.bonuses?.[rarity]??0;
  }
  return bonuses;
}
export function boostedRarityWeights(weights, level, c = defaults) {
  const result={...weights}, bonuses=levelBonuses(level,c);
  const requested=Object.entries(bonuses).reduce((sum,[rarity,value])=>result[rarity] == null ? sum : sum+value,0);
  const applied=Math.min(result.common??0,requested);
  if(requested<=0 || applied<=0) return result;
  result.common-=applied;
  for(const [rarity,value] of Object.entries(bonuses)) if(result[rarity] != null) result[rarity]+=value*(applied/requested);
  return result;
}
// A fixed UTC boundary (03:00 by default) has no daylight-saving ambiguity.
export function dailyCycle(now, c = defaults) {
  const offset = c.resetHourUtc * 3600000;
  const start = Math.floor((now - offset) / 86400000) * 86400000 + offset;
  return {id: new Date(start).toISOString().slice(0,10), resetsAt: start + 86400000};
}
export function normalizeWorldCoinEconomy(user, cycleId, c = defaults) {
  const rawBalance = user?.worldCoins;
  const worldCoins = Number.isSafeInteger(rawBalance) && rawBalance >= 0
    ? rawBalance
    : 0;
  const rawRewards = user?.worldCoinRewardAds;
  const earned = rawRewards?.cycleId === cycleId &&
    Number.isSafeInteger(rawRewards?.earnedToday) && rawRewards.earnedToday >= 0
    ? rawRewards.earnedToday
    : 0;
  return {
    worldCoins,
    worldCoinRewardAds: {
      cycleId,
      earnedToday: Math.min(earned, c.worldCoin.dailyAdLimit),
    },
  };
}
// Weekly exploration runs from Monday 00:00 through Sunday 13:00 in the
// configured local timezone (03:00 UTC offset for America/Sao_Paulo).
export function weeklyCycle(now, c = defaults) {
  const offset = c.resetHourUtc * 3600000;
  const local = new Date(now - offset);
  const localMidnight = Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate());
  const daysSinceMonday=(local.getUTCDay()+6)%7;
  const start=localMidnight-daysSinceMonday*86400000+offset;
  const endsAt=start+6*86400000+13*3600000;
  const nextStartsAt=start+7*86400000;
  return {id:new Date(start-offset).toISOString().slice(0,10),start,endsAt,nextStartsAt,resetsAt:now<endsAt?endsAt:nextStartsAt,active:now>=start&&now<endsAt};
}
export function regenerate(user, now, c = defaults) {
  let lives = Math.min(c.lives.maximum, user.lives);
  let anchor = Math.min(now, user.lifeAnchor);
  const amount = Math.max(0, Math.floor((now - anchor) / c.lives.regenerationMs));
  const gained = Math.min(c.lives.maximum - lives, amount);
  lives += gained;
  anchor = lives === c.lives.maximum ? now : anchor + gained * c.lives.regenerationMs;
  return {lives, lifeAnchor: anchor};
}
export function dailyDifficulty(value) {
  return typeof value === 'string' ? value : value?.bestDifficulty;
}
export function explorationScore(countries, c = defaults) {
  return Object.values(countries).reduce((sum, value) => sum + (c.dailyPoints[dailyDifficulty(value)] ?? 0), 0);
}
export function explorationTier(countries, c = defaults) {
  const values = Object.values(countries);
  if (values.length !== c.requiredCountries || values.some(value => !difficulties[dailyDifficulty(value)])) throw new Error('Incomplete exploration');
  const score = explorationScore(countries, c);
  return 1 + c.dailyRewardMilestones.slice(1).filter(milestone => score >= milestone).length;
}
export function weighted(weights, random = () => randomInt(0, 1000000000)/1000000000) {
  let pick = random() * weights.reduce((a,b)=>a+b,0);
  for (let i=0; i<weights.length; i++) { pick -= weights[i]; if (pick < 0) return i; }
  return weights.findLastIndex(w=>w>0);
}
export function move(board, grid, position) {
  const blank = board.indexOf(board.length-1);
  if (!Number.isInteger(position) || position < 0 || position >= board.length || Math.abs(Math.floor(position/grid)-Math.floor(blank/grid))+Math.abs(position%grid-blank%grid)!==1) throw new Error('Illegal move');
  [board[position], board[blank]] = [board[blank], board[position]];
}
export function shuffledBoard(grid) {
  const board = Array.from({length:grid*grid}, (_,i)=>i);
  let previous = -1;
  for(let n=0;n<grid*grid*40;n++) {
    const blank=board.indexOf(board.length-1);
    const options = board.map((_,i)=>i).filter(i=>i!==previous && Math.abs(Math.floor(i/grid)-Math.floor(blank/grid))+Math.abs(i%grid-blank%grid)===1);
    move(board,grid,options[randomInt(options.length)]); previous=blank;
  }
  if(board.every((v,i)=>v===i)) move(board,grid,board.length-2);
  return board;
}
export function verifySolution(attempt, moves, now) {
  if (!Array.isArray(moves) || moves.length < 1 || moves.length > attempt.config.maxMoves || now-attempt.startedAt < attempt.config.minCompletionMs || now>attempt.expiresAt) throw new Error('Invalid attempt');
  const board = [...attempt.board];
  for(const position of moves) move(board, attempt.grid, position);
  if(!board.every((v,i)=>v===i)) throw new Error('Puzzle is not solved');
  const limits = difficulties[attempt.difficulty];
  if(moves.length > limits.moves || now-attempt.startedAt > limits.seconds*1000) throw new Error('Attempt limits exceeded');
}
export function verifyJigsawSolution(attempt, placements, moveCount, now) {
  const count=attempt.grid*attempt.grid;
  if(!Array.isArray(placements) || placements.length!==count ||
    !Number.isInteger(moveCount) || moveCount<placements.length || moveCount>attempt.config.maxMoves ||
    now-attempt.startedAt<attempt.config.minCompletionMs || now>attempt.expiresAt) throw new Error('Invalid attempt');
  const sorted=[...placements].sort((a,b)=>a-b);
  if(sorted.some((value,index)=>value!==index)) throw new Error('Puzzle is not solved');
  if(!jigsawLimits[attempt.difficulty]) throw new Error('Invalid difficulty');
}
export function verifyBlocksSolution(attempt, lines, score, piecesLocked, now) {
  const limits=blocksLimits[attempt.difficulty];
  if(!limits || !Number.isInteger(lines) || lines<limits.targetLines || lines>limits.targetLines+3 ||
    !Number.isInteger(score) || score<0 || score>5000000 ||
    !Number.isInteger(piecesLocked) || piecesLocked<Math.ceil(lines/4) || piecesLocked>attempt.config.maxMoves ||
    now-attempt.startedAt<attempt.config.minCompletionMs || now>attempt.expiresAt) throw new Error('Invalid attempt');
}
