extends Node

var hasManaUpgrade = false
var hasLifeUpgrade = false
var hasAttackUpgrade = false
var hasSpeedUpgrade = false
var hasJumpUpgrade = false

var MAX_HP = 3
var HP = 3
var MAX_MP = 3
var MP = 3
var MP_COST = 1
var MP_COST_2 = 2
var MPS = 1
var damage = 1
var SPEED = 500.0
var extra_jumps = 1

func reset():
	hasManaUpgrade = false
	hasLifeUpgrade = false
	hasAttackUpgrade = false
	hasSpeedUpgrade = false
	hasJumpUpgrade = false
	MAX_HP = 3
	HP = 3
	MAX_MP = 3.0
	MP = 3.0
	MP_COST = 1
	MP_COST_2 = 2
	MPS = 1
	damage = 1
	SPEED = 500.0
	extra_jumps = 1
