
require 'charHealthBase'

#
# setup and helper methods
#
#

$damage_types = Hash.new {|h,k| h[k] = nil}
$damage_subtypes = Hash.new {|h,k| h[k] = Hash.new {|h2,k2| h2[k2] = nil}
$damage_specials = Hash.new {|h,k| h[k] = Hash.new {|h2,k2| h2[k2] = nil}

[
	:physical,
	:fatigue,
	:energy,
	:toxic,
].each_with_index {|x,i| $damage_types[x] = i}

def defineSpecials(damageType, *specialTypes)
	i = 0 
	h = $damage_specials[damageType)
	specialTypes.each_with_index {|x,i| h[x] = i}
	h
end

def defineSubtypes(damageType, *subTypes)
	i = 0 
	h = $damage_subtypes[damageType)
	subTypes.each_with_index {|x,i| h[x] = i}
	h
end

def dtype(*ps)
	WoundMatch.new(
		$damage_types[ps.shift],
		$damage_subtypes[ps.shift],
		Wound.Severity[ps.shift],
		$damage_specials[ps.shift]
	)
end

$default_heal_rules = []
def defineHealRule(dt, amount, age)
	$default_heal_rules << WoundHealRule.new( 
		dt, 
		amount, 
		age.nil? ? Wound.MaxWoundAge + 1 : age 
	) 
end
$default_deal_rules = []
def defineDealRule(dt, th, cf)
	return if th.nil?
	$default_deal_rules <<  WoundAggrevateRule.new(dt, th, cf)
end

###########################
# define details about damage types here
###########################

#
# physical
#
defineSubtypes(:physical, *[
	:slash,
	:stab,
	:impact
])

defineSpecials(:physical, *[
	:critical,
	:head,
	:left_arm,
	:right_arm
])

defineHealRule(dtype(:physical), 2,5)
defineHealRule(dtype(:slash,nil,nil,:critical),2,7)
defineHealRule(dtype(:slash,nil,nil,:head),2,7)

defineDealRule(dtype(:physical),35,2)
defineDealRule(dtype(:physical,nil,:major),25,2)

defineDealRule(dtype(:physical,nil,nil,:critical),25,2)
defineDealRule(dtype(:physical,nil,:major,:critical),15,2)

defineDealRule(dtype(:physical,nil,nil,:head),25,2)
defineDealRule(dtype(:physical,nil,:major,:head),15,2)

#stab
stab_base_heal_ages = {
	nil => 10,
	:critical => 15, :head => 15,
	:left_arm => 8, :right_arm => 8
}
stab_base_heal_agemods = {
	nil => Proc.new {|a| a},
	:major => Proc.new {|a| a * 2}
	:massive => Proc.new {|a| (a * 2) + 10}
}
stab_base_heal_ages.each do |special,age| stab_base_heal_agemods.each do |severity,mod|
	defineHealRule(dtype(:physical,:stab,severity,special) 1, mod.call(age))
end

defineDealRule(dtype(:physical,pierce),20,3)
defineDealRule(dtype(:physical,:stab,nil,:critical),18,2)
defineDealRule(dtype(:physical,:stab,:major),18,3)
defineDealRule(dtype(:physical,:stab,:major,:critical),14,2)

#impact
defineHealRule(dtype(:physical,:impact,nil,:head),1,30)
defineHealRule(dtype(:physical,:impact,:major,:head),1,60)
defineHealRule(dtype(:physical,:impact,:massive,:head),1,120)

[:left_arm,:right_arm].each do |arm|
	defineHealRule(dtype(:physical,:impact,nil,arm),1,10)
	defineHealRule(dtype(:physical,:impact,:major,arm),1,16)
	defineHealRule(dtype(:physical,:impact,:massive,arm),1,32)
end

defineDealRule(dtype(:impact,nil,:head),10,2)
defineDealRule(dtype(:impact,:major,:head),5,2)

#
# fatigue
#

defineSubtypes(:fatigue, *[
	:stamina,
	:mana
])

defineSpecials(:fatigue, *[
	:extreme
])

#stamina
defineHealRule(dtype(:fatigue,:stamina), 2,5)
defineHealRule(dtype(:fatigue,:stamina,nil,:extreme), 1,25)

defineDealRule(dtype(:fatigue,:stamina), 30, 2)
defineDealRule(dtype(:fatigue,:stamina,nil,:extreme), 10, 1)

#mana
defineHealRule(dtype(:fatigue,:mana), 2,50)
defineHealRule(dtype(:fatigue,:mana,:major), 2,100)
defineHealRule(dtype(:fatigue,:mana,nil,:extreme), 1,250)
defineHealRule(dtype(:fatigue,:mana,:major,:extreme), 1,500)

defineDealRule(dtype(:fatigue,:mana), 20, 2)
defineDealRule(dtype(:fatigue,:mana,nil,:extreme), 5, 1)

#
# energy
#

defineSubtypes(:energy, *[
	:burn,
	:freeze,
	:electric,
	:dark,
	:sundry
])

defineSpecials(:energy, *[
	:bale,
	:pure
])

defineHealRule(dtype(:energy), 1, 25)
defineHealRule(dtype(:energy,nil,:moderate), 1, 35)
defineHealRule(dtype(:energy,nil,:major), 1, 50)
defineHealRule(dtype(:energy,nil,:massive), 1, 70)

defineHealRule(dtype(:energy,nil,nil,:bale), 1, 100)
defineHealRule(dtype(:energy,nil,:moderate,:bale), 1, 125)
defineHealRule(dtype(:energy,nil,:major,:bale), 1, 175)
defineHealRule(dtype(:energy,nil,:massive,:bale), 1, 250)

defineDealRule(dtype(:energy), 15, 2)
defineDealRule(dtype(:energy,nil,:major), 10, 2)

defineDealRule(dtype(:energy), 15, 2)
defineDealRule(dtype(:energy,nil,:major), 10, 2)

defineDealRule(dtype(:energy,nil,nil,:bale), 10, 2)
defineDealRule(dtype(:energy,nil,:major,:bale), 5, 2)

defineDealRule(dtype(:energy,nil,nil,:pure), 10, 2)
defineDealRule(dtype(:energy,nil,:major,:pure), 5, 2)

#
# toxic
#

defineSubtypes(:toxic, *[
	:poison,
	:disease
])

defineSpecials(:physical, *[
	:deadly
])

defineHealRule(dtype(:toxic,:poison), 1, 4)
defineHealRule(dtype(:toxic,:disease), 1, 50)

defineDealRule(dtype(:toxic,:poison), 15, 3)
defineDealRule(dtype(:toxic,:poison,nil,:deadly), 10, 2)

disease_deal_threshold = {
	:minor => 40,
	:moderate => 35,
	:major => 25,
	:massive => 10
}
disease_deal_threshold.each do |severity,th|
	defineDealRule(dtype(:toxic,:disease,severity), th, 2)
	defineDealRule(dtype(:toxic,:disease,nil,:deadly), th/2, 1)
end


