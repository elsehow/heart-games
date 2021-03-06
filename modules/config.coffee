# experiment config
experiment = 

	SURVEY_URL: 'http://goo.gl/forms/wct4wh1akm'

# config about the game 
game = 

	# num of points players get on new round
	POINTS_ON_NEW_ROUND: 10

#
# GLOBAL BOT CONFIG
# these apply to all bots
#
globalBotConfig = 

	# time to do entrust turn (ms)
	ENTRUST_TURN_TIME_MIN: 20 
	ENTRUST_TURN_TIME_MAX: 2000 

	# time to do cooperate defect turn
	COOPERATE_DEFECT_TURN_TIME_MIN: 20 
	COOPERATE_DEFECT_TURN_TIME_MAX: 2000

	# time to proceed to the next round
	READY_NEXT_ROUND_TIME_MIN: 20 
	READY_NEXT_ROUND_TIME_MAX: 2000 

#
# HEARTRATE CONDITION CONFIG
#
heartrateConditionConfig = 

	# elevated heartrate config
	ELEVATED_HEARTRATE_MEAN_MIN: 80
	ELEVATED_HEARTRATE_MEAN_MAX: 90 #mean
	ELEVATED_HEARTRATE_STD_MIN: 6
	ELEVATED_HEARTRATE_STD_MAX: 16 
	ELEVATED_HEARTRATE_INTERPRETATION: "Your partner's biosignals were elevated."

	# normal heartrate config
	NORMAL_HEARTRATE_MEAN_MIN: 20
	NORMAL_HEARTRATE_MEAN_MAX: 60 #mean
	NORMAL_HEARTRATE_STD_MIN: 4
	NORMAL_HEARTRATE_STD_MAX: 13 
	NORMAL_HEARTRATE_INTERPRETATION: "Your partner's biosignals were normal."



exports.experiment = experiment
exports.game = game
exports.globalBotConfig = globalBotConfig
exports.heartrateConditionConfig = heartrateConditionConfig
