local D={Interval=24*60*60}
D.Rewards={
 {Name="Coin bag",Coins=1000,Share=0.01,Icon="Coins"},
 {Name="Luck potion ×1",Potions={Luck=1},Icon="Luck"},
 {Name="Big coin bag",Coins=2500,Share=0.025,Icon="Coins"},
 {Name="Speed potion ×2",Potions={Speed=2},Icon="Speed"},
 {Name="Coin potion ×2",Potions={Coins=2},Icon="Potion"},
 {Name="Luck potion ×3",Potions={Luck=3},Icon="Luck"},
 {Name="Coin chest + 3 potions",Coins=10000,Share=0.06,Potions={Coins=1,Speed=1,Luck=1},Icon="Star"},
}
-- Монеты награды растут с игроком: не меньше Coins и не меньше доли Share от всего заработанного.
function D.CoinsFor(reward,lifetime) return math.floor(math.max(reward.Coins or 0,(reward.Share or 0)*(tonumber(lifetime) or 0))) end
function D.State(day,last,now)
 day=math.clamp(math.floor(tonumber(day) or 0),0,7)
 last=math.max(0,tonumber(last) or 0)
 return {Day=day%7+1,Ready=last==0 or now>=last+D.Interval,Remaining=math.max(0,last+D.Interval-now)}
end
return D
