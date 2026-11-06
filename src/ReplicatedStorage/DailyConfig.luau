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
 {Name="JACKPOT",Coins=25000,Share=0.2,Potions={SuperCoins=1,SuperSpeed=1,SuperLuck=1},FreeHatch=3,RushKeys=1,Icon="Star"},
}
-- Монеты награды растут с игроком: не меньше Coins и не меньше доли Share от всего заработанного.
function D.CoinsFor(reward,lifetime) return math.floor(math.max(reward.Coins or 0,(reward.Share or 0)*(tonumber(lifetime) or 0))) end
function D.State(day,last,now)
 day=math.clamp(math.floor(tonumber(day) or 0),0,7)
 last=math.max(0,tonumber(last) or 0)
 local nextAt=(math.floor(last/D.Interval)+1)*D.Interval -- полночь UTC после прошлой награды
 return {Day=day%7+1,Ready=last==0 or now>=nextAt,Remaining=math.max(0,nextAt-now)}
end
return D
