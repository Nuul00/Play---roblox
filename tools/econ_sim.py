"""CoinSprint economy simulator: a greedy 'average player' progressing through the game."""
import math, random, json, sys

CAT = json.load(open(sys.argv[1] if len(sys.argv) > 1 else 'catalog.json'))
P = dict(eff=0.55, seed=1, hours=12, verbose=False)
for a in sys.argv[2:]:
    k, v = a.split('='); P[k] = float(v)

def tier(l):
    T = [P.get('t%d' % i, d) for i, d in enumerate((3, 8, 25, 90, 300), 1)]
    return T[4] if l >= 100 else T[3] if l >= 75 else T[2] if l >= 50 else T[1] if l >= 25 else T[0] if l >= 10 else 1
def upc(base, g, l):
    gg = g**50 * 1.18**(l - 50) if l > 50 else g**l
    return math.floor(base * gg * tier(l) + .5)
COST = dict(speed=lambda l: upc(10, 1.34, l), magnet=lambda l: upc(8, 1.34, l),
            income=lambda l: upc(20, 1.36, l), double=lambda l: upc(40, 1.36, l))
def walk(l): return 16 + 4*min(l, 10) + 2*max(0, min(l-10, 15)) + max(0, min(l-25, 25)) + .4*max(0, min(l-50, 75))
def mrad(l): return 3 + .4*l
def income(l): return 1 + .25*l
def dbl(l): return .015*l if l <= 50 else min(.9, .75 + .002*(l-50))
def nice(x):
    if x < 100: return round(x)
    m = 10**(math.floor(math.log10(x)) - 1); return round(x/m)*m
def rcost(r): return nice(10**(P.get('ra',5.4) + P.get('rb',.42)*r - P.get('rc',.003)*r*r))
def reggs(r): return max(10, math.floor((10 + 15*r + 1.2*r*r)/5 + .5)*5)
def rbonus(r): return 1 + .75*r + .05*max(0, r-10)**2
SLOTS_AT = {3: 1, 10: 1, 25: 1}
WORLDS = [  # id, gate speed, coins, area, avg value, shop cap
    ('island', 0, 115, 300*460, 7.5, 10), ('neon', 3, 90, 300*460, 43.25, 25), ('sky', 6, 110, 300*300, 240, 50),
    ('frozen', 10, 140, 440*440, 640, 75), ('volcano', 13, 165, 440*440, 4480, 100), ('galaxy', 16, 195, 440*440, 31360, 125)]
for i, w in enumerate(WORLDS):
    g = P.get('gate%d' % i)
    if g is not None: WORLDS[i] = (w[0], int(g)) + w[2:]
MAGNETS = [(0, 0), (150, .5), (400, 1), (900, 1.5), (1800, 2), (3500, 2.7), (6000, 3.4), (1e4, 4.2), (16e3, 5), (25e3, 6), (4e4, 7), (6e4, 8.2), (9e4, 9.5),
           (13e4, 11), (2e5, 12.5), (3e5, 14), (45e4, 16), (65e4, 18), (9e5, 20), (15e5, 23), (25e5, 26), (4e6, 30), (65e5, 34), (1e7, 39), (15e6, 45),
           (23e6, 52), (35e6, 60), (55e6, 70), (85e6, 82), (15e7, 100)]
WIDX = {'island':0,'neon':1,'sky':2,'frozen':3,'volcano':4,'galaxy':5}
for e in CAT:
    m = P.get('em%d' % WIDX[e['World']], 1)
    e['Price'] = P.get('p%d' % e['Id'], e['Price']*m)
EGGS = {e['Id']: e for e in CAT}
WORLD_EGGS = {}
for e in CAT: WORLD_EGGS.setdefault(e['World'], []).append(e['Id'])

rng = random.Random(int(P['seed']))
def roll(eid):
    r = rng.random()*100; acc = 0
    for p in EGGS[eid]['Pets']:
        acc += p['Chance']
        if r <= acc: return p['Multiplier']
    return EGGS[eid]['Pets'][-1]['Multiplier']

class S: pass
s = S()
s.t = 0; s.coins = 0.0; s.lv = dict(speed=0, magnet=0, income=0, double=0); s.mag = 0; s.pets = []; s.reb = 0; s.eggs = 0
s.log = []; s.lastrate = 0; s.seen = set(); s.earned = 0.0; s.hatch_ready = 0
def slots(): return 3 + sum(v for k, v in SLOTS_AT.items() if s.reb >= k)
def team():
    top = sorted(s.pets, reverse=True)[:slots()]
    return 1 + sum(m - 1 for m in top)
UNLOCK=[0]+[P.get('u%d'%i,0) for i in range(1,6)]
s.unl=1
def access(): return [w for i,w in enumerate(WORLDS) if s.lv['speed'] >= w[1] and i < s.unl]
def cap(): return max(w[5] for w in access())
def rate(w=None):
    w = w or max(access(), key=lambda w: w[4])
    v = walk(s.lv['speed']); r = mrad(s.lv['magnet']) + MAGNETS[s.mag][1]
    d = 0.65*math.sqrt(w[3]/w[2])  # средний путь между монетами
    per = v/max(d - r, 1.5) * P['eff']
    per = min(per, w[2]/8*P.get('cap',.6))
    return per * w[4] * income(s.lv['income']) * team() * rbonus(s.reb) * (1 + dbl(s.lv['double']))
def note(key, msg):
    if key not in s.seen:
        s.seen.add(key); s.log.append((s.t, msg + ' earned %.2g' % s.earned, s.lastrate))
def best_egg():
    # самое дорогое яйцо доступного мира, которое ещё можно купить за ~60 c дохода
    eggs = [i for w in access() for i in WORLD_EGGS[w[0]]]
    return max(eggs, key=lambda i: EGGS[i]['Price'])
def egg_gain(eid):
    top = sorted(s.pets, reverse=True)[:slots()]
    weak = top[-1] if len(top) >= slots() else 1
    return sum(p['Chance']/100*max(0, p['Multiplier'] - weak) for p in EGGS[eid]['Pets'])

T = P['hours']*3600
while s.t < T:
    s.t += 1
    inc = rate(); s.lastrate = inc; s.coins += inc; s.earned += inc
    for w in access(): note('w' + w[0], 'world ' + w[0])
    # rebirth
    if s.coins >= rcost(s.reb) and s.eggs >= reggs(s.reb) and s.reb < 50:
        s.reb += 1; s.coins = 0; s.lv = dict(speed=6, magnet=0, income=0, double=0); s.eggs = 0
        note('r%d' % s.reb, 'REBIRTH %d' % s.reb); continue
    while s.unl < 6 and s.coins >= UNLOCK[s.unl] and s.lv['speed'] >= WORLDS[s.unl][1]:
        s.coins -= UNLOCK[s.unl]; s.unl += 1
    # человеческая стратегия: 1) открыть мир 2) яйца (самое дорогое доступное) 3) самая дешёвая прокачка
    saving = s.unl < 6 and UNLOCK[s.unl] > s.coins and UNLOCK[s.unl] - s.coins < s.lastrate*P.get('save',240)
    if s.t >= s.hatch_ready and not saving:
        eggs = sorted([i for w in access() for i in WORLD_EGGS[w[0]]], key=lambda i: -EGGS[i]['Price'])
        need = s.eggs < reggs(s.reb) and s.coins >= rcost(s.reb)
        if need:  # для ребёрса добиваем количество самыми полезными яйцами, что не мешают накоплению
            eggs = [i for i in eggs if EGGS[i]['Price']*9 <= max(s.coins - rcost(s.reb), s.coins*0.01)] or [min(eggs, key=lambda i: EGGS[i]['Price'])]
        for eid in eggs:
            n = 9 if s.coins >= EGGS[eid]['Price']*9 else 3 if s.coins >= EGGS[eid]['Price']*3 else 0
            # яйцо ещё полезно, или нужны яйца для ребёрса
            useful = egg_gain(eid) > 0.02*team() or need
            if n and useful and (EGGS[eid]['Price']*n <= s.coins*P.get('eggshare',0.6) or need):
                s.coins -= EGGS[eid]['Price']*n
                for _ in range(n): s.pets.append(roll(eid))
                s.pets = sorted(s.pets, reverse=True)[:12]
                s.eggs += n; s.hatch_ready = s.t + 3.5
                note('e%d' % eid, 'egg %d %s (%g)' % (eid, EGGS[eid]['Name'], EGGS[eid]['Price']))
                break
    for _ in range(80):
        if saving and s.lv['speed'] >= WORLDS[s.unl][1]: break
        opts = []
        for k in s.lv:
            l = s.lv[k]
            if l < cap(): opts.append((COST[k](l) * (0.5 if k == 'speed' else 1), COST[k](l), 'up', k))
        if s.mag + 1 < len(MAGNETS): opts.append((MAGNETS[s.mag+1][0], MAGNETS[s.mag+1][0], 'mag', None))
        if not opts: break
        o = min(opts)
        if o[1] > s.coins*P.get('upshare',0.5) or (s.eggs >= reggs(s.reb) and s.coins >= rcost(s.reb)*0.4): break
        s.coins -= o[1]
        if o[2] == 'up': s.lv[o[3]] += 1
        else: s.mag += 1
    if P['verbose'] and s.t % int(P.get('every',600)) == 0:
        print('%5.0fm coins %.3g rate %.3g/s spd %d mag %d inc %d dbl %d magnet %d team %.4g reb %d unl %d' % (s.t/60, s.coins, rate(), s.lv['speed'], s.lv['magnet'], s.lv['income'], s.lv['double'], s.mag, team(), s.reb, s.unl))
for t, m, r in s.log:
    print('%7.1f min  %-40s income %.3g/s' % (t/60, m, r))
print('END reb', s.reb, 'team %.4g' % team(), 'levels', s.lv)
