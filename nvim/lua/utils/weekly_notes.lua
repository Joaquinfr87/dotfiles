local M = {}

local function get_week_info(date)
  date = date or os.date("*t")
  
  local function iso_week(y, m, d)
    local a = math.floor((14 - m) / 12)
    local y2 = y + 4800 - a
    local m2 = m + 12 * a - 3
    local j = d + math.floor((153 * m2 + 2) / 5) + 365 * y2 + math.floor(y2 / 4) - math.floor(y2 / 100) + math.floor(y2 / 400) - 32045
    local week = math.floor(((j + 42059 - (j % 7)) % 146097 % 36524 % 1461) / 7) + 1
    if week > 52 then
      week = 1
    end
    return week, y
  end
  
  local week, year = iso_week(date.year, date.month, date.day)
  
  return {
    week = week,
    year = year,
    filename = string.format("%04d-W%02d", year, week),
    display = string.format("Semana %02d - %d", week, year),
  }
end

local function replace_template_vars(content, info)
  local date_str = os.date("%Y-%m-%d")
  content = content:gsub("{{week%-id}}", info.filename)
  content = content:gsub("{{week%-number}}", string.format("%02d", info.week))
  content = content:gsub("{{year}}", tostring(info.year))
  content = content:gsub("{{date}}", date_str)
  return content
end

function M.open_weekly_note()
  local info = get_week_info()
  local folder = "weekly"
  local full_path = vim.fn.expand("~") .. "/repos/notas/" .. folder .. "/" .. info.filename .. ".md"
  
  if vim.fn.filereadable(full_path) == 1 then
    vim.cmd("edit " .. full_path)
    return
  end
  
  local template_path = vim.fn.expand("~") .. "/repos/notas/templates/weekly-note.md"
  local f = io.open(template_path, "r")
  if not f then
    vim.notify("Template not found: " .. template_path, vim.log.levels.ERROR)
    return
  end
  local content = f:read("*all")
  f:close()
  
  content = replace_template_vars(content, info)
  
  vim.fn.mkdir(vim.fn.expand("~") .. "/repos/notas/" .. folder, "p")
  local wf = io.open(full_path, "w")
  if wf then
    wf:write(content)
    wf:close()
  end
  
  vim.cmd("edit " .. full_path)
end

function M.open_previous_week()
  local today = os.date("*t")
  local prev = os.time(today) - (7 * 24 * 60 * 60)
  local prev_date = os.date("*t", prev)
  local info = get_week_info(prev_date)
  
  local folder = "weekly"
  local full_path = vim.fn.expand("~") .. "/repos/notas/" .. folder .. "/" .. info.filename .. ".md"
  
  if vim.fn.filereadable(full_path) == 1 then
    vim.cmd("edit " .. full_path)
  else
    vim.notify("Weekly note not found: " .. info.filename, vim.log.levels.WARN)
  end
end

function M.open_next_week()
  local today = os.date("*t")
  local nxt = os.time(today) + (7 * 24 * 60 * 60)
  local nxt_date = os.date("*t", nxt)
  local info = get_week_info(nxt_date)
  
  local folder = "weekly"
  local full_path = vim.fn.expand("~") .. "/repos/notas/" .. folder .. "/" .. info.filename .. ".md"
  
  if vim.fn.filereadable(full_path) == 1 then
    vim.cmd("edit " .. full_path)
  else
    vim.notify("Weekly note not found: " .. info.filename, vim.log.levels.WARN)
  end
end

return M
