extends Node2D

var deck = []
var table = []
var pot = 0
var players = []

enum Rank {High, Pair, TwoPair, Three, Straight, Flush, FullHouse, Four, StraightFlush, RoyalFlush}

func inverseStraightSort(a,b):
	return a.value > b.value;
	
func straightSort(a,b):
	return a.value < b.value;
	
func inverseFlushSort(a,b):
	if(a.suit == b.suit):
		return a.value > b.value
	return a.suit < b.suit;
	
func flushSort(a,b):
	if(a.suit == b.suit):
		return a.value < b.value
	return a.suit < b.suit;
	

func findValue(hand, value):
	var i = 0
	for c in hand:
		if c.value == value:
			return i
		i += 1
	return -1
	
func findSuit(hand, suit):
	var a = []
	for c in hand:
		if c.suit == suit:
			a.push_back(c)
	return a
	
func hasCard(hand, card):
	for c in hand:
		if c.suit == card.suit && c.value == card.value:
			return true
	return false
	
func countValue(hand, value):
	var arr = []
	for c in hand:
		if c.value == value:
			arr.push_back(c)
	return arr

func checkFlush(hand):
	var suit = hand[0].suit
	for c in hand:
		if c.suit != suit:
			return false
	return true

func straightCheck(hand):
	var count = 0
	var high = 0
	var prev = 14
	var str_arr = []
	
	for c in hand:
		if c.value == 2 && str_arr.size() == 4:
			str_arr.push_back(c)
			var val = findValue(hand,14)
			if val != -1:
				str_arr.push_back(hand[val])
		elif c.value != prev-1 && c.value != prev:
			str_arr = [c]
			high = c.value
		elif c.value == prev-1:
			str_arr.push_back(c)
			count += 1
		prev = c.value
		if(str_arr.size() == 5):
			return str_arr
	return []
	
func fourCheck(hand):
	var count = 0
	var four_arr = []
	for c in hand:
		if four_arr.size() == 0:
			four_arr.push_back(c)
		elif c.value == four_arr.back().value:
			four_arr.push_back(c)
		
		if four_arr.size() == 4:
			return four_arr
	return []
	
func fullHouseCheck(hand):
	hand.sort_custom(inverseStraightSort);
	var three = []
	var two = []
	for c in hand:
		var cV = countValue(hand, c.value)
		if (cV.size() == 3 && three.size() == 0):
			three = cV
		elif(cV.size() == 3 && three.size() != 0 && c.value != three[0].value):
			cV.pop_back()
			two = cV
		elif(cV.size() == 2 && two.size() == 0):
			two = cV
			
		if (three.size() != 0 && two.size() != 0):
			return three + two
	return []
	
func threeCheck(hand):
	hand.sort_custom(inverseStraightSort);
	var three = []
	var second = []
	for c in hand:
		var cV = countValue(hand, c.value)
		if (cV.size() == 3):
			return cV
	return []
	
func pairCheck(hand):
	hand.sort_custom(inverseStraightSort);
	var first = []
	var second = []
	for c in hand:
		var cV = countValue(hand, c.value)
		if (cV.size() == 2 && first.size() == 0):
			first = cV
		elif(cV.size() == 2 && first.size() != 0 && c.value != first[0].value):
			second = cV
			return first + second
	if first.size() != 0:
		return first
	return []
	
func reduceHand(hand, total):
	var handcopy = hand + []
	handcopy.sort_custom(inverseStraightSort)
	if hand.size() > 5:
		for i in range(hand.size() - 5):
			hand.pop_back()
	if hand.size() < 5:
		total.sort_custom(inverseStraightSort)
		for j in range(5 - hand.size()):
			for c in total:
				if(!hasCard(hand, c)):
					hand.push_back(c)
					break
	
func calculateCash(p):
	return p.money - p.bet;
	
func compareCombos(a, b):
	a.sort_custom(inverseStraightSort)
	b.sort_custom(inverseStraightSort)
	for i in range(a.size()):
		if a[i].value < b[i].value:
			return 1
		if a[i].value > b[i].value:
			return 0
	return 2

func cWinner(winnerList):
	var s = ""
	for w in winnerList:
		s += "👑" + str(w[0].id) + cHand(w[1][2])
	return s
	
func checkWinner():
	var winners = []
	for p in players:
		if(!p.folded && !p.disconnected):
			winners.push_back([p,evaluateCombo(p.hand + table)])
	
	var result = []
	for w in winners:
		if result.size() == 0:
			result.push_back(w)
			continue
		if w[1][0] > result[0][1][0]:
			result = [w]
			continue
		if w[1][0] == result[0][1][0]:
			var r = compareCombos(w[1][2], result[0][1][2])
			if(r == 0):
				result = [w]
			elif(r == 2):
				var r1 = compareCombos(w[1][1], result[0][1][1])
				if(r1 == 0):
					result = [w]
				elif(r == 2):
					result.push_back(w)
	return result
	
func evaluateCombo(hand):
	hand.sort_custom(inverseFlushSort);
	print(cHand(hand))
	
	var r = Rank.High
	var result = []
	
	var suits = [findSuit(hand,Card.suitType.CLUB),
				findSuit(hand,Card.suitType.SPADE),
				findSuit(hand,Card.suitType.HEART),
				findSuit(hand,Card.suitType.DIAMOND)]
	for s in suits:
		if s.size() >= 5:
			r = Rank.Flush
			var st = straightCheck(s)
			if(st.size() != 0):
				r = Rank.StraightFlush
				if(findValue(st, 14) != -1 && findValue(st, 13) != -1):
					r = Rank.RoyalFlush
			result = s
	if r < Rank.StraightFlush:			
		hand.sort_custom(inverseStraightSort);
		var f = fourCheck(hand)
		if f.size() != 0:
			r = Rank.Four
			result = f
			
	if r < Rank.Four:
		var f = fullHouseCheck(hand)
		if f.size() == 5:
			r = Rank.FullHouse
			result = f
	
	if r < Rank.Flush:
		hand.sort_custom(inverseStraightSort);
		var st = straightCheck(hand)
		if st.size() != 0:
			r = Rank.Straight
			result = st
	
	if r < Rank.Straight:
		var t = threeCheck(hand)
		if t.size() == 3:
			r = Rank.Three
			result = t
	
	if r < Rank.Three:
		var tp = pairCheck(hand)
		if tp.size() == 4:
			r = Rank.TwoPair
			result = tp
		if tp.size() == 2:
			r = Rank.Pair
			result = tp
	var originalHand = hand + []
	reduceHand(result, hand)
	if(originalHand.size() > 5):
		originalHand = result
	print(cHand(result))
	match r:
		Rank.High: print("HIGH CARD")
		Rank.Pair: print("PAIR")
		Rank.TwoPair: print("TWO PAIR")
		Rank.Three: print("THREE OF A KIND")
		Rank.Straight: print("STRAIGHT")
		Rank.Flush: print("FLUSH")
		Rank.FullHouse: print("FULL HOUSE")
		Rank.Four: print("FOUR OF A KIND")
		Rank.StraightFlush: print("STRAIGHT FLUSH")
		Rank.RoyalFlush: print("ROYAL STRAIGHT FLUSH")
	return [r, result, originalHand]

func cSuit(suit):
	match suit:
		0: return "♥"
		1: return "♦"
		2: return "♠"
		3: return "♣"
	return null

func cValue(val):
	match val:
		11: return "J"
		12: return "Q"
		13: return "K"
		14: return "A"
	return str(val)

func cString(card):
	return cSuit(card.suit) + cValue(card.value)

func cHand(hand):
	var s = ""
	for c in hand:
		s += cString(c) + " "
	return s

func resetDeck():
	deck = []
	for i in 4:
		for j in range(2,15):
			var suit = Card.suitType.HEART
			match i:
				0: suit = Card.suitType.HEART
				1: suit = Card.suitType.DIAMOND
				2: suit = Card.suitType.SPADE
				3: suit = Card.suitType.CLUB
			deck.append(Card.new(suit, j))

func shuffleDeck():
	deck.shuffle()

func getValidPlayers():
	var count = 0
	for p in players:
		if(getValidActions(p).size() != 0):
			count+=1
	return count;
	
func getValidPlayersPlayed():
	var count = 0
	for p in players:
		if(getValidActions(p).size() != 0 && p.played):
			count+=1
	return count;

func checkFlop():	
	if(getValidPlayers() <= 1):
		return true;
	for p in players:
		#They must either be all in, with the bet amount, folded, disconnected, or folded
		if(p.disconnected || p.folded):
			continue;
			
		if p.played && (p.bet == currentBet || p.money == p.bet):
			continue;
		else:
			return false;
	return true;

func drawDeck():
	return deck.pop_back()
	
func onRound():
	for p in players:
		p.played = false
		
	
func drawTable():
	table.push_back(deck.pop_back())


func startGame():
	players.shuffle()
	resetDeck()
	shuffleDeck()
	startMatch()

var currentPlayer = 0;

const bbValue = 50
const sbValue = 25

var currentBet = 0;

func recalculatePot():
	var potValue = 0
	for p in players:
		potValue += p.bet
	pot = potValue


func setBet(player, value):
	player.bet = min(value, player.money)
	recalculatePot()
	
func increaseBet(player, value):
	player.bet = min(value + currentBet, player.money)
	currentBet = max(currentBet, player.bet)
	recalculatePot()



func deal(player):
	player.hand = []
	player.hand.push_back(drawDeck())
	player.hand.push_back(drawDeck())
	print("Dealt " + cHand(player.hand) + "to " + str(player.id))

enum PLAYER_ACTIONS{CHECK, BET, FOLD, CALL}

func countInvalidPeople():
	var count = 0
	for p in players:
		if(p.folded || p.disconnected || p.money == p.bet):
			count += 1
	return count;

func findMaxBet():
	var max = 0
	for p in players:
		if(p.bet > max):
			max = p.bet
	return max;
	
func findBiggestRaise(id):
	var max = 0
	for p in players:
		if(p.money > max && p.id != id && !(p.folded || p.disconnected)):
			max = p.money
	return max;

func getValidActions(p : Player):
	if(p.folded || p.disconnected):
		return [] 
	if(p.money == p.bet):
		return [] #ALL-IN
	if(countInvalidPeople() == players.size() - 1 && p.bet == currentBet):
		return [PLAYER_ACTIONS.CHECK]
	if(p.bet < currentBet && currentBet == findBiggestRaise(p.id)):
		return [PLAYER_ACTIONS.FOLD, PLAYER_ACTIONS.CALL]
	if(p.bet < currentBet):
		return [PLAYER_ACTIONS.FOLD, PLAYER_ACTIONS.CALL, PLAYER_ACTIONS.BET]
	if(p.bet == currentBet):
		return [PLAYER_ACTIONS.CHECK, PLAYER_ACTIONS.BET, PLAYER_ACTIONS.FOLD]
	return []

func pCall(p : Player):
	setBet(p, currentBet)
	p.played = true
	
func pCheck(p : Player):
	p.played = true
	
func pFold(p : Player):
	p.folded = true
	p.played = true
	
func pBet(p : Player, value: int):
	increaseBet(p, value)
	p.played = true

func startMatch():
	table = []
	for i in range(players.size()-1,-1,-1):
		if players[i].disconnected:
			players.remove_at(i)
	for i in range(players.size()):
		players[i].played = false
		players[i].folded = false
		var j = (players.size()-1) - i
		match j:
			0: players[i].blind = Player.BigBlind
			1: players[i].blind = Player.SmallBlind
			2: players[i].blind = Player.Dealer
			_: players[i].blind = Player.NoBlind
		if(players[i].blind == Player.BigBlind):
			setBet(players[i], bbValue)
		if(players[i].blind == Player.SmallBlind):
			setBet(players[i], sbValue)
		deal(players[i])
		currentBet = bbValue

func testDeck():
	randomize()
	resetDeck()
	shuffleDeck()
	var hand = [drawDeck(),drawDeck(),drawDeck(),drawDeck(),drawDeck(),drawDeck(),drawDeck()]
	evaluateCombo(hand)

func _ready():
	pass

class Card:
	enum suitType {HEART, DIAMOND, SPADE, CLUB}
	var suit : suitType
	var value : int	
	func _init(s=suitType.HEART, v=1):
		suit = s
		value = v
		pass

class Player:
	enum {NoBlind, BigBlind, SmallBlind, Dealer}
	var avatar_id : int = 0
	var hand = []
	var money = 1000
	var bet = 0
	var folded = false
	var played = false
	var id = -1
	var ready = false
	var blind = NoBlind
	var disconnected = false
	var nickname = "Player"

func _process(delta):
	pass
