function math.clamp(min, value, max)
    if min > max then min, max = max, min end
    return math.max(min, math.min(max, value))
end

function filter(table, condition)
    local result = {}
    for k, v in pairs(table) do
        if condition(v) then
            result[k] = v
        end
    end
    return result
end

function count(table, condition)
    local result = 0
    for k, v in pairs(table) do
        if condition(v) then
            result = result + 1
        end
    end
    return result
end
