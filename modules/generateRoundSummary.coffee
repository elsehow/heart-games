_ = require 'lodash'


entrustTurnSummary = (subject, pointsEntrusted, directObject) ->
	_.template('<%=subject%> <span class="goodThing"> entrusted </span> <%=pointsEntrusted%> points to <%=directObject%>. ')(
		subject: subject
		pointsEntrusted: pointsEntrusted
		directObject: directObject)

cooperateDefectTurnSummary = (subject, decision, directObject) ->
	if decision == 'cooperate'
		decision = '<span class="goodThing"> returned </span>'
	else
		decision = '<span class="badThing"> kept </span>'
	return _.template('<%=subject%> <%=decision%> the points <%=directObject%> entrusted. ')(
		subject: subject
		decision: decision
		directObject: directObject)

roundEarningsSummary = (earnings) ->
	_.template('<%= earnings %> points have been added to your bank. ')(earnings:earnings)

getFirstParagraph = (youEntrusted, yourPartnerDecided) -> 
	if youEntrusted == 0
		return '<p> You entrusted <span class="badThing"> nothing </span> to your partner. </p>'
	return '<p>' + entrustTurnSummary('You', youEntrusted, 'your partner', ) +
	cooperateDefectTurnSummary('Your partner', yourPartnerDecided, 'you') + '</p>' 

getSecondParagraph = (yourPartnerEntrusted, youDecided) ->
	if yourPartnerEntrusted == 0
		return '<p>Your partner entrusted you with <span class="badThing"> nothing </span>.</p>'
	return '<p>' + entrustTurnSummary('Your partner', yourPartnerEntrusted, 'you', ) +
	cooperateDefectTurnSummary('You', youDecided, 'your partner') + '</p>' 


generateRoundSummary = (round, roundEarnings) ->

	humanState = round.humanState
	botState = round.botState

	# extract human / bot actions for first paragraph
	humanEntrusted = humanState.entrustTurn.pointsEntrusted
	botDecision = botState.cooperateDefectTurn.decision

	# extract human / bot actions for second paragraph
	botEntrusted = botState.entrustTurn.pointsEntrusted
	humanDecision = humanState.cooperateDefectTurn.decision

	# get texts
	firstParagraph = getFirstParagraph(humanEntrusted, botDecision)
	secondParagraph = getSecondParagraph(botEntrusted, humanDecision)
	earningsSummary =  roundEarningsSummary(roundEarnings)

	return firstParagraph + secondParagraph + '<p>' + earningsSummary + '</p>'

module.exports = generateRoundSummary