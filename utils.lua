function math.clamp(min, value, max)
	if min > max then min, max = max, min end
	return math.max(min, math.min(max, value))
end