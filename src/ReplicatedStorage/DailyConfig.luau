-- Новая награда — каждый новый календарный день по UTC (раньше: ровно через 24 ч после прошлой,
-- и забравший в 20:00 назавтра в 18:00 ничего не получал). Пропуск дня прогресс не сбрасывает.
local D={Interval=24*60*60}
-- Награды недели: то, чего не купить за монеты — СУПЕР-зелья, ключи Coin Rush, бесплатные яйца.
-- Монеты — доля от всего заработанного (растут вместе с игроком). FreeHatch — сколько яиц
-- открыть бесплатно (самое дорогое яйцо лучшего открытого мира, двойная удача).
D.Rewards={
 {Name="Coin bag",Coins=2000,Share=0.04,Icon="Coins"},
 {Name="Super Luck potion",Potions={SuperLuck=1},Icon="SuperLuck"},
 {Name="Coin pile + Rush key",Coins=5000,Share=0.08,RushKeys=1,Icon="CoinPile"},
 {Name="Super Coin + Super Speed",Potions={SuperCoins=1,SuperSpeed=1},Icon="SuperCoins"},
 {Name="2 Coin Rush keys",RushKeys=2,Icon="Key"},
 {Name="2 Super Luck potions",Potions={SuperLuck=2},Icon="SuperLuck"},
 {Name="JACKPOT",Coins=25000,Share=0.08,Potions={SuperCoins=1,SuperSpeed=1,SuperLuck=1},FreeHatch=3,RushKeys=1,Icon="Star"},
}
-- Недели подряд (Save_DailyWeek, +1 после джекпота 7-го дня): каждая следующая неделя щедрее —
-- +1 к зельям, ключам и бесплатным яйцам каждого дня и +50% к монетам, до 4-й недели (потом так же).
-- Раньше неделя повторялась без изменений и после первой не давала нового повода заходить.
D.WeekAttr="Save_DailyWeek"
D.MaxWeekBonus=3
function D.Week(raw) return math.clamp(math.floor(tonumber(raw) or 0),0,D.MaxWeekBonus) end
function D.RewardFor(day,weekRaw)
 local base=D.Rewards[day]
 local w=D.Week(weekRaw)
 if not base or w==0 then return base end
 local r=table.clone(base)
 if r.Coins then r.Coins=math.floor(r.Coins*(1+0.5*w)) end
 if r.Share then r.Share=r.Share*(1+0.5*w) end
 if base.Potions then r.Potions={} for name,n in pairs(base.Potions) do r.Potions[name]=n+w end end
 if r.RushKeys then r.RushKeys+=w end
 if r.FreeHatch then r.FreeHatch=(r.FreeHatch==true and 1 or r.FreeHatch)+w end
 return r
end
-- Монеты награды растут с игроком: не меньше Coins и не меньше доли Share от всего заработанного.
-- 2026-11 (аудит): LifetimeEarned не обнуляется при ребёрсе, и доля от него давала до 40% следующего
-- ребёрса за один заход. Доля теперь не больше 5% цены следующего ребёрса.
function D.CoinsFor(reward,lifetime,rebirths)
 local share=(reward.Share or 0)*(tonumber(lifetime) or 0)
 if rebirths~=nil then
  local ok,Config=pcall(require,script.Parent:WaitForChild("GameConfig"))
  if ok and Config.GetRebirthCost then share=math.min(share,0.05*Config.GetRebirthCost(math.floor(tonumber(rebirths) or 0))) end
 end
 return math.floor(math.max(reward.Coins or 0,share))
end
function D.State(day,last,now)
 day=math.clamp(math.floor(tonumber(day) or 0),0,7)
 last=math.max(0,tonumber(last) or 0)
 local nextAt=(math.floor(last/D.Interval)+1)*D.Interval -- полночь UTC после прошлой награды
 return {Day=day%7+1,Ready=last==0 or now>=nextAt,Remaining=math.max(0,nextAt-now)}
end
return D
