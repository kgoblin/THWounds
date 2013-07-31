
require 'charHealthBase'

#
# setup and helper methods
#
#

i = 0
[
	:slash,
	:stab,
	:impact,
	:burn,
	:magic_drain,
	:blind,
	:freeze,
	:electric,
	:fatigue,
].each do |damageType|
	$damage_types[damageType] = i
	i += 1
end

def defineSpecials(damageType, *specialTypes)
	i = 0 
	h = $damage_special_types[damageType)
	specialTypes.each do |specType|
		h[specType] = i
		i += 1
	end
	h
end

def dtype(type, severity = nil, special = nil)
	dt = $damage_types[damageType]
	st = $damage_severity[severity]
	spt = $damaget_special_types[damageType][special]
	WoundMatch.new(dt,st,spt)
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

#slash
defineSpecials(:slash, *[
	:critical,
	:head,
	:left_arm,
	:right_arm,
])

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

