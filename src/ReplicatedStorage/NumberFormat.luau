-- Единое сокращение чисел для всего интерфейса: 1250 → 1.25K, 1 250 000 → 1.25M, 3.4e17 → 340Qa.
-- Раньше у каждого окна была своя копия (где-то 1.3M, где-то 1,250,000, где-то без Sp).
local NumberFormat = {}
local UNITS = { { 1e30, "No" }, { 1e27, "Oc" }, { 1e24, "Sp" }, { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }

function NumberFormat.Short(n: number?): string
	n = tonumber(n) or 0
	if n ~= n or n == math.huge then
		return "∞"
	end
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	for _, u in ipairs(UNITS) do
		-- 0.9995: 999 999 округляется до «1000K» — такие числа сразу показываем как 1M
		if n >= u[1] * 0.9995 then
			local v = n / u[1]
			-- 3 значащие цифры: 1.25M, 12.5M, 125M
			local f = v >= 100 and "%.0f" or v >= 10 and "%.1f" or "%.2f"
			local str = string.format(f, v)
			if string.find(str, ".", 1, true) then -- нули срезаем только после точки: 200K не должно стать 2K
				str = str:gsub("0+$", ""):gsub("%.$", "")
			end
			return sign .. str .. u[2]
		end
	end
	return sign .. string.format("%g", math.floor(n * 10 + 0.5) / 10)
end

return NumberFormat
