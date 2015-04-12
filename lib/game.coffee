_ = require 'lodash'

playerBot = require './playerBot.coffee'

# configuration

POINTS_ON_NEW_ROUND = 10




# returns true if both turns have been played
bothTurnsPlayed = (turn1, turn2) -> if turn1 and turn2 then true else false

# returns {botTurn, humanTurn}
getEntrustTurns = (round) ->
	return {
		botTurn: round.botState.entrustTurn
		, humanTurn: round.humanState.entrustTurn }

# returns {botTurn, humanTurn}
getCooperateDefectTurns = (round) ->
	return {
		humanTurn: round.humanState.cooperateDefectTurn
		botTurn: round.botState.cooperateDefectTurn }

# returns {botTurn, humanTurn}
getReadyForNextRoundTurns = (round) ->
	return { 
		humanTurn: round.humanState.readyForNextRound
		botTurn: round.botState.readyForNextRound }





# takes object data: {subject_id, station_num, humanBank, botBank}
# returns an object representing a round
initializeNewGame = (data) ->
	return { 
		# save the socket
		subject_id: data.subject_id
		station_num: data.station_num
		subject_is_connected: true
		round_num: 0
		currentTurn: null
		# make them a bot to play against
		bot: playerBot
		# bot game state
		botState: getFreshActorState(0)
		# human game state 
		humanState: getFreshActorState(0) }

# the state of an actor (on new round)
getFreshActorState = (bankAmount) ->
	return { 
		entrustTurn: null
		cooperateDefectTurn: null
		readyForNextRound: null
		bank: bankAmount }





# actor's earnings from a round
getRoundEarnings = (actorState, opponentState) ->
	# if opponent defected:
	if opponentState.cooperateDefectTurn.decision == 'defect'
		# subtract amount actor entrusted to opponent
		return -actorState.entrustTurn.pointsEntrusted
	# if opponent cooperated,
	# double amount actor entrusted to opponent
	return 2*actorState.entrustTurn.pointsEntrusted

# function takes a round
# returns an object {botBank, humanBank}
getBankAmounts = (round) ->
	return {
		botBank: round.botState.bank + getRoundEarnings(round.botState, round.humanState), 
		humanBank: round.humanState.bank + getRoundEarnings(round.humanState, round.botState) }





entrustTurnSummary = (subject, pointsEntrusted, directObject) ->
	if pointsEntrusted == 0
		pointsEntrusted = 'nothing'
	else:
		pointsEntrusted += ' points'
	_.template('<%=subject%> entrusted <%=pointsEntrusted%> to <%=directObject%>. ')(
		subject: subject
		pointsEntrusted: pointsEntrusted
		directObject: directObject)

cooperateDefectTurnSummary = (subject, decision, directObject) ->
	if decision == 'cooperate'
		decision = 'returned'
	else
		decision = 'kept'
	return _.template('<%=subject%> <%=decision%> the points <%=directObject%> entrusted. ')(
		subject: subject
		decision: decision
		directObject: directObject)

roundEarningsSummary = (earnings) ->
	_.template('<%= earnings %> points have been added to your bank. ')(earnings:earnings)

getHumanSummary = (humanState, botState) ->
	return '<p>' + entrustTurnSummary('You', humanState.entrustTurn.pointsEntrusted, 'your partner', ) + 
	cooperateDefectTurnSummary('Your partner', botState.cooperateDefectTurn.decision, 'you') + '</p>' +

	'<p>' + entrustTurnSummary('Your partner', botState.entrustTurn.pointsEntrusted, 'you', ) + 
	cooperateDefectTurnSummary('You', humanState.cooperateDefectTurn.decision, 'your partner') + '</p>' +	

	'<p>' + roundEarningsSummary(getRoundEarnings(humanState, botState)) + '</p>'




# resets the round 
# + iterates round_num
# TODO: calculate bank amounts
setNextRoundState = (round, banks) ->
	round.currentTurn = null
	round.botState = getFreshActorState(banks.botBank)
	round.humanState = getFreshActorState(banks.humanBank)
	round.round_num = round.round_num+1


# this function checks if a round is done
# if it is, it
# (1) tells the human about the bot's move
# (2) starts the bot on playing its next move
checkRoundCompletion = (round, emitToSubject, pushGamesToAdmins) ->

	# entrust turn
	if round.currentTurn == 'entrustTurn'
		turns = getEntrustTurns(round)
		startNextRoundFn = startCooperateDefectTurn 

	# c or d turn
	if round.currentTurn == 'cooperateDefectTurn'
		turns = getCooperateDefectTurns(round)
		startNextRoundFn = startReadyForNextRoundTurn

	# ready for next round message
	if round.currentTurn == 'readyForNextRound'
		turns = getReadyForNextRoundTurns(round)	
		startNextRoundFn = startEntrustTurn

	# if both turns have been played, 
	# start the next turn
	if bothTurnsPlayed(turns.humanTurn, turns.botTurn)
		startNextRoundFn(round, emitToSubject, pushGamesToAdmins)
			

# TODO save/log round data here
startEntrustTurn = (round, emitToSubject, pushGamesToAdmins) ->
	# RESET ROUND STATE
	banks = getBankAmounts(round)
	setNextRoundState(round, banks)

	# send the client the points they can use during the next round
	clientMessage = 'opponentReadyForNextRound'
	clientPayload = {points: POINTS_ON_NEW_ROUND}
	nextTurn = 'entrustTurn'
	nextBotTurnFn = round.bot.playEntrustTurn

	startTurn(round, clientMessage, clientPayload, nextTurn, nextBotTurnFn, emitToSubject, pushGamesToAdmins)


startCooperateDefectTurn = (round, emitToSubject, pushGamesToAdmins) ->
	# we send the client the bot's entrust turn
	clientMessage = 'opponentEntrustTurn'
	clientPayload = getEntrustTurns(round).botTurn
	nextTurn = 'cooperateDefectTurn'
	nextBotTurnFn = round.bot.playCooperateDefectTurn

	startTurn(round, clientMessage, clientPayload, nextTurn, nextBotTurnFn, emitToSubject, pushGamesToAdmins)


startReadyForNextRoundTurn = (round, emitToSubject, pushGamesToAdmins) ->
	# we send the client a summary of the round
	clientMessage = 'roundSummary'
	nextTurn = 'readyForNextRound'
	nextBotTurnFn = round.bot.playReadyForNextRound
	clientPayload = 
				{summary: getHumanSummary(round.humanState, round.botState)
				, bank: getBankAmounts(round).humanBank}

	startTurn(round, clientMessage, clientPayload, nextTurn, nextBotTurnFn, emitToSubject, pushGamesToAdmins)

startTurn = (round, clientMessage, clientPayload, nextTurn, nextBotTurnFn, emitToSubject, pushGamesToAdmins) ->
		# emit bot's turn to human
		emitToSubject(round.subject_id, clientMessage, clientPayload)
		# start bot going on next turn
		nextBotTurnFn(round, emitToSubject, pushGamesToAdmins, checkRoundCompletion)
		# set round to the next round
		round.currentTurn = nextTurn
		# update admins
		pushGamesToAdmins()



exports.initializeNewGame = initializeNewGame
exports.checkRoundCompletion = checkRoundCompletion
exports.startEntrustTurn = startEntrustTurn