
class Wound
	def self.Severity()
		{
			:minor => 1,
			:moderate => 2,
			:major => 3,
			:massive => 4
		}.freeze
	end
	def self.MaxSeverity() ; self.Severity.values.max ; end
	def self.MinSeverity() ; self.Severity.values.min ; end
	def self.MaxDamageValue() ; 9999 ; end
	def self.MaxWoundAge() ; 999 ; end
		
	
	attr_accessor :type, :subtype, :severity, :special, :amount, :age
	
	def initialize(t, st, s, amt, sp = nil)
		@special = sp
		@type = t
		@subtype = st
		@severity = s
		@age = 0
		@amount = amt
	end
	
	def amount()
		@amount = 0 if @amount < 0
		@amount = Wound.MaxDamageValue if @amount > Wound.MaxDamageValue
		@amount
	end
	
	def age()
		@age = 0 if @age < 0
		@age = Wound.MaxWoundAge if @age > Wound.MaxWoundAge
		@age
	end
	
	def <=>(other)
		compares = [
			(self.type <=> other.type),
			(self.subtype <=> other.subtype),
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
	attr_reader :type, :subtype, :severity, :special
	
	def initialize(*ps)
		@type = ps.shift
		@subtype = ps.shift
		@severity = ps.shift
		@special = ps.shift
	end

	def <=>(other)
		compares = [
			(self.type <=> other.type),
			(self.subtype <=> other.subtype),
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
			(!self.subtype.nil? and (wound.subtype == self.subtype)),
			(!self.severity.nil? and (wound.severity >= self.severity)),
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

class WoundHealRule

	attr_reader :match, :amount, :age

	def initialize(woundmatch, amt, age)
		@match = woundmatch
		@amount = amt
		@age = age
	end
	
	def <=>(other)
		self.match <=> other.match
	end
end

class WoundAggrevateRule

	def initialize(woundmatch, th, cf)
		@match = woundmatch
		@threshold = th
		@factor = cf
	end
	
	def <=>(other)
		self.match <=> other.match
	end
end

#
# wound space holds wounds & tempers
#
class WoundSpace

	attr_reader :wounds, :atempers , :btempers, :conditions, :healrules, :dealrules
	
	def initialize()
		@atempers = {}
		@btempers = {}
		@conditions = []
		@wounds = []
		@healrules = []
		@dealrules = []
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
			m = hr.match.match_count(wound)
			next unless m > 0
			next unless m >= xhrm
			xhrm = m
			xhra = 0
			next unless hr.age <= wound.age
			next unless hr.amount > xhra
			xhra = hr.amount
		end
		
		{:amount => xhra}
	end
	
	def find_aggrevate_rule(wound)
		xdrm = 0
		xdra = 0
		xdrn = 0
		xdrc = 0
		@dealrules.each do |dr|
			m = dr.match.match_count(wound)
			next unless m > 0
			next unless m >= xhrm
			xdrm = m
			a = dr.threshold
			n = (wound.amount - a) / dr.factor
			c = (a + (2*n))
			next unless c > xdrc
			xdrc = c
			next unless a < wound.amount
			next unless n > 0
			xdra = a
			xdrn = n
		end
		
		{:current_wound_amount = xdra, :new_wound_amount = xdrn}
	end
	
	def tick!()
		drp_wounds = []
		add_wounds = []
		@wounds.each do |wound|
			@wound.age += 1
			
			#heal with best applicable rule
			hr = find_heal_rule(wound)
			
			if hr[:amount] > 0
				@wound.amount -= hr[:amount]
				@wound.age = 0
			end
			
			if (wound.amount == 0)
				drp_wounds << wound
				next if wound.severity == Wound.MinSeverity
				add_wounds << Wound.new(wound.type, wound.severity - 1, hr[:amount] + wound.severity, wound.special)
				next
			end
			
			#dont go into aggrevate phase if at max possible damage severity
			next if wound.severity == Wound.MaxSeverity
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


