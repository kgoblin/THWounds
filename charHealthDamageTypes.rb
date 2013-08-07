
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
	:blind
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
		age.nil? ? $max_wound_age + 1 : age 
	) 
end
$default_deal_rules = []
def defineDealRule(dt,  th, cf)
	return if th.nil?
	$default_deal_rules <<  WoundAggrevateRule.new(dt, th, cf)
end

#
#
# define details about damage types here
#

defineSubtypes(:physical, *[
	:slash,
	:pierce,
	:impact
])

defineSpecials(:physical, *[
	:critical,
	:head,
	:left_arm,
	:right_arm
])

#slash

defineHealRule(dtype(:slash),2,5)
defineHealRule(dtype(:slash,nil,:critical),2,7)
defineHealRule(dtype(:slash,nil,:head),1,5)

defineDealRule(dtype(:slash),35,2)
defineDealRule(dtype(:slash,:major),25,2)

defineDealRule(dtype(:slash,nil,:critical),25,2)
defineDealRule(dtype(:slash,:major,:critical),15,2)

defineDealRule(dtype(:slash,nil,:head),25,2)
defineDealRule(dtype(:slash,:major,:head),15,2)

#stab
defineSpecials(:stab, *[
	:critical,
	:head,
	:left_arm,
	:right_arm,
])

defineHealRule(dtype(:stab),1,10)
defineHealRule(dtype(:stab,nil,:critical),1,15)
defineHealRule(dtype(:stab,nil,:head),1,15)
defineHealRule(dtype(:stab,nil,:left_arm),1,8)
defineHealRule(dtype(:stab,nil,:right_arm),1,8)

defineHealRule(dtype(:stab,:major),1,20)
defineHealRule(dtype(:stab,:major,:critical),1,30)
defineHealRule(dtype(:stab,:major,:head),1,30)
defineHealRule(dtype(:stab,:major,:left_arm),1,16)
defineHealRule(dtype(:stab,:major,:right_arm),1,16)

defineHealRule(dtype(:stab,:massive),1,30)
defineHealRule(dtype(:stab,:massive,:critical),1,40)
defineHealRule(dtype(:stab,:massive,:head),1,40)
defineHealRule(dtype(:stab,:massive,:left_arm),1,26)
defineHealRule(dtype(:stab,:massive,:right_arm),1,26)

defineDealRule(dtype(:stab),20,3)
defineDealRule(dtype(:stab,nil,:critical),18,2)
defineDealRule(dtype(:stab,:major),18,3)
defineDealRule(dtype(:stab,:major,:critical),14,2)

#impact
defineSpecials(:stab, *[
	:critical,
	:head,
	:left_arm,
	:right_arm,
])

defineHealRule(dtype(:impact),1,5)
defineHealRule(dtype(:impact,nil,:head),1,30)
defineHealRule(dtype(:impact,nil,:left_arm),1,10)
defineHealRule(dtype(:impact,nil,:right_arm),1,10)

defineHealRule(dtype(:impact,:major),1,10)
defineHealRule(dtype(:impact,:major,:head),1,60)
defineHealRule(dtype(:impact,:major,:left_arm),1,16)
defineHealRule(dtype(:impact,:major,:right_arm),1,16)

defineHealRule(dtype(:impact,:massive),1,10)
defineHealRule(dtype(:impact,:massive,:head),1,120)
defineHealRule(dtype(:impact,:massive,:left_arm),1,32)
defineHealRule(dtype(:impact,:massive,:right_arm),1,32)

defineDealRule(dtype(:impact),25,3)
defineDealRule(dtype(:impact,nil,:head),10,2)
defineDealRule(dtype(:impact,:major,:head),5,2)

