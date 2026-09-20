local M = {}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function pin_sort_key(pin)
  if pin:match("^%d+$") then
    return 0, tonumber(pin), pin
  end
  local mount = pin:match("^MP(%d+)$")
  if mount then
    return 1, tonumber(mount), pin
  end
  return 2, pin, pin
end

local function escape_pattern(value)
  return (tostring(value or ""):gsub("([^%w])", "%%%1"))
end

function M.latex_escape(value)
  value = tostring(value or "")
  value = value:gsub("\\", "\\textbackslash{}")
  value = value:gsub("([%%#$&_{}])", "\\%1")
  value = value:gsub("~", "\\textasciitilde{}")
  value = value:gsub("%^(.)", "\\textasciicircum{}%1")
  return value
end

-- Parse a Protel-style netlist block list and extract a pin -> net mapping.
-- Returns a Lua array of tables: { pin = "1", net = "NetName" }
function M.parse_protel_netlist(path, ref)
  local file, err = io.open(path, "r")
  if not file then
    return nil, err
  end

  local entries = {}
  local seen = {}
  local in_block = false
  local current_net = nil
  local target_prefix = escape_pattern(ref) .. "%-"

  for raw_line in file:lines() do
    local line = trim(raw_line)

    if line == "(" then
      in_block = true
      current_net = nil
    elseif line == ")" then
      in_block = false
      current_net = nil
    elseif in_block and line ~= "" then
      if not current_net then
        current_net = line
      else
        local pin = line:match("^" .. target_prefix .. "(%d+)$") or line:match("^" .. target_prefix .. "(MP%d+)$")
        if pin and not seen[pin] then
          seen[pin] = true
          table.insert(entries, { pin = pin, net = current_net })
        end
      end
    end
  end

  file:close()

  table.sort(entries, function(left, right)
    local left_group, left_value = pin_sort_key(left.pin)
    local right_group, right_value = pin_sort_key(right.pin)
    if left_group ~= right_group then
      return left_group < right_group
    end
    if left_value ~= right_value then
      return left_value < right_value
    end
    return tostring(left.pin) < tostring(right.pin)
  end)

  return entries
end

function M.render_pin_rows(entries)
  local rows = {}

  for _, entry in ipairs(entries or {}) do
    table.insert(rows, string.format("%s & %s \\\\", M.latex_escape(entry.pin), M.latex_escape(entry.net)))
  end

  return rows
end

return M
