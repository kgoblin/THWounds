
$max_damage_value = 9999
$max_wound_age = 999

$damage_types = Hash.new {|h,k| h[k] = 0}
$damage_severity = {
	:minor => 1,
	:moderate => 2,
	:major => 3,
	:massive => 4,
}
$damage_severity.freeze!

class Wound
	attr_accessor :type, :severity, :special, :amount, :age
	
	def initialize(t,s, amt, sp = nil)
		@special = sp
		@type = t
		@severity = s
		@age = 0
		@amount = amt
	end
	
	def amount()
		@amount = 0 if @amount < 0
		@amount = $max_damage_value if @amount > $max_damage_value
		@amount
	end
	
	def <=>(other)
		compares = [
			(self.type <=> other.type),
			(self.severity <=> other.severity),
			(self.special <=> other.special),
			(self.age <=> other.age),
			(self.amount <=> other.amount),
		]
		
		cv = 0
		compares.each do |c| 
			cv = c
			if (cv != 0) return cv
		end
		return cv
	end
	
end

class WoundMatch
	attr_reader :type, :severity, :special\
	
	def initialize(t,s,sp)
		@type = t
		@severity = s
		@special = sp
	end

	def <=>(other)
		compares = [
			(self.type <=> other.type),
			(self.severity <=> other.severity),
			(self.special == other.special ? 0 : (self.special.nil? ? -1 :  self.special <=> other.special)),
		]
		
		cv = 0
		compares.each do |c| 
			cv = c
			if (cv != 0) return cv
		end
		return cv
	end
	
	def match_count(wound)
		[
			(!self.type.nil? and (wound.type == self.type)),
			(!self.severity.nil? and (wound.severity == self.severity)),
			(
				(wound.special.nil? and self.special.nil?) 
				or 
				(!self.special.nil? and (wound.special == self.special))
			),
		].reject(false).size
	end

	def match?(wound)
		self.match_count(wound) > 0
	end
end

#
# wound space holds wounds & tempers
#
class WoundSpace

	attr_reader :wounds, :atempers , :btempers, :conditions
	
	def initialize()
		@atempers = {}
		@btempers = {}
		@conditions = []
		@wounds = []
		@healrules = []
		@dealrules = []
	end
	
	def define_heal_rule(woundmatch, amt, age)
		@heal_woundrules << {
			:match => woundmatch,
			:amount => amt,
			:age => age
		}
		self
	end
	
	def define_aggrevate_rule(woundmatch, amt, factor)
		@deal_woundrules = {
			:match => woundmatch,
			:amount => amt,
			:factor => factor
		}
		self
	end
	
	def add_atemper(name, temper)
		@atempers[name] =  temper
	end
	
	def add_btemper(name, temper)
		@btempers[name] = temper
	end
	
	def status()
		{
			:wounds => @wounds.map {|w| w.dup},
			:conditions => self.conditions(),
			:atempers => Hash.new {|h,k| h[k] = [@atempers[k].current, @atempers[k].cmax]},
			:btempers => Hash.new {|h,k| h[k] = [@btempers[k].current, @btempers[k].cmax]},
		}
	end
	
	def find_heal_rule(wound)
		xhrm = 0
		xhra = 0
		@healrules.each do |hr|
			m = hr[:match].match_count(wound)
			next unless m > 0
			next unless m >= xhrm
			next unless hr[:age] <= wound.age
			next unless hr[:amount] > xhra
			xhrm = m
			xhra = hr[:amount]
		end
		
		{:amount => xhra}
	end
	
	def find_aggrevate_rule(wound)
		xdrm = 0
		xdra = 0
		xdrn = 0
		xdrc = 0
		@dealrules.each do |dr|
			m = dr[:match].match_count(wound)
			next unless m > 0
			next unless m >= xhrm
			a = dr[:amount]
			next unless a < wound.amount
			n = (wound.amount - a) / dr[:factor]
			c = (a + (2*n))
			next unless c > xdrc
			xdrm = m
			xdra = a
			xdrn = n
			xdrc = c
		end
		
		{:current_wound_amount = xdra, :new_wound_amount = xdrn}
	end
	
	def tick!()
		drp_wounds = []
		add_wounds = []
		@wounds.each do |wound|
			@wound.age += 1 unless wound.age.nil?
			@wound.age = nil if @wound.age >= $max_wound_age
			
			#heal with best applicable rule
			hr = find_heal_rule(wound)
			@wound.amount -= hr[:amount]
			if (wound.amount == 0)
				drp_wounds << wound
				next
			end
			
			#dont go into aggrevate phase if at max possible damage severity
			next if wound.severity == $damage_severity.values.max
			dr = find_aggrevate_rule(wound)
			next if dr[:new_wound_amount] == 0
			wound.amount = dr[:current_wound_amount]
			add_wounds << Wound.new(wound.type, wound.severity+1, dr[:new_wound_amount], wound.special)
		end
	
		@wounds -= drp_wounds
		@wounds += add_wounds
		@wounds.sort!
		
		#update tempers
		atempers = @atempers.values.sort
		btempers = @btempers.values.sort
		@wounds.each do |wound|
			btempers.each {|temper| temper.absorb(wound)}
			amt = wound.amount
			atempers.each do |temper|
				take = temper.absorb(wound)
				amt -= take
				break if amt <= 0
			end
		end
		
		@conditions.clear
		@conditions += (atempers.collect {|t| t.conditions}).flatten
		@conditions += (btempers.collect {|t| t.conditions}).flatten
		@conditions.uniq!
		
		self
	end

end

#
# a temper absorbs damage to cause an effect to the character
#
class Temper

	attr_reader :current, :max, :cmax
	
	def initialize()
		@arules = []
		@crules = []
		@buffs = Hash.new {|h,k| h[k] = 0}
		@max = 0
		@cmax = 0
		@current = 0
	end
	
	def def_absorb_rule(arule)
		@arules << arule
	end
	
	def def_condition_rule(crule)
		@crules << crule
	end
	
	def max=(v)
		v = v.abs
		ov = @max
		@max = v
		@cmax = (@cmax - ov + v)
		@current -= (v - ov) if (v - ov) > 0
		@max
	end
	
	def add_buff_amt(type, buff)
		@buffs[type] += buff
		@cmax += buff
		@current -= buff
		@current = 0 if (@current < 0)
	end
	def drop_buff_amt(type,buff)
		@buffs[type] -= buff
		@buffs[type] = 0 if (@buffs[type] < 0)
		@cmax -= buff
		@cmax = @max if (@cmax < @max)
		@current = @cmax if (@current > @cmax)
	end
	def drop_all_buffs()
		@buffs.clear()
		@cmax = @max
		@current = @cmax if (@current > @cmax)
	end
	
	def absorb?(wound)
		curr = @current
		rv = self.absorb(wound)
		@current = curr
		rv
	end
	
	def absorb(wound)
		mults = []
		@arules.each do |rule|
			next unless rule.match?(wound)
			mults << rule.multiplier
		end
		
		return 0 if mults.empty?
		amt = wound.amount
		multv = mults.reduce(:*)
		mamt = amt * multv
		@current += mamt
		if @current > @cmax
			amt = (mamt - (@current - @cmax)) / multv
			@current = @cmax
		end
		
		amt
	end
	alias :absorb :deal

	def status()
		conditions = @crules.map {|rule| rule.apply?(@current,@cmax) ? rule.condition : nil}
		conditions.compact.sort
	end
	
end

#
# temper absorb rules dictate what damage a temper can absorb, and at what rate (multiplier)
#
class TemperAbsorbRule

	attr_reader :woundmatch, :multiplier

	def initialize(wm,m = 1)
		@woundmatch = wm
		@multiplier = m
	end
	
	def match?(wound)
		@woundmatch.match?(wound)
	end
	
	def <=>(other)
		wm = self.woundmatch <=> other.woundmatch
		return wm unless wm == 0
		self.multiplier <=> other.multiplier
	end
end

#
# temper condition rules render a character status condition when temper is at certain state
#
class TemperConditionRule
	attr_reader :condition, :bound, :percent

	def initialize(c, b, p)
		@condition = c
		@bound = b
		@percent = p.to_f
	end
	
	def apply?(current, max)
		target = (max.to_f * @percent) / 100.0
		compare = current <=> target
		(compare == 0) || (compare == @bound)
	end

end


