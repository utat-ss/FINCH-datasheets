local pc104 = {}

local function sanitize(str)
    str = string.gsub(str, "I%^2C", "I\\textsuperscript{2}C")
    str = string.gsub(str, "_", "\\_")
    return str
end

local function split_csv(line)
    local res = {}
    local pos = 1
    while true do
        local c = string.sub(line, pos, pos)
        if c == "" then break end
        if c == '"' then
            local txt = ""
            pos = pos + 1
            while true do
                local nextc = string.sub(line, pos, pos)
                if nextc == "" then break end
                if nextc == '"' then
                    if string.sub(line, pos+1, pos+1) == '"' then
                        txt = txt .. '"'
                        pos = pos + 2
                    else
                        pos = pos + 1
                        break
                    end
                else
                    txt = txt .. nextc
                    pos = pos + 1
                end
            end
            table.insert(res, txt)
            if string.sub(line, pos, pos) == ',' then pos = pos + 1 end
        else
            local startp = pos
            while true do
                local nextc = string.sub(line, pos, pos)
                if nextc == "" or nextc == ',' then break end
                pos = pos + 1
            end
            table.insert(res, string.sub(line, startp, pos-1))
            if string.sub(line, pos, pos) == ',' then pos = pos + 1 end
        end
    end
    return res
end

local function read_csv(filename)
    local f = io.open(filename, "r")
    if not f then return nil end
    local data = {}
    local header = true
    for line in f:lines() do
        line = line:gsub("\r$", "")
        local row = split_csv(line)
        if header then header = false
        else if #row >= 2 then table.insert(data, row) end
        end
    end
    f:close()
    return data
end

function pc104.gen_table14()
    local data = read_csv("pc104.csv")
    if not data then tex.sprint("Error reading pc104.csv"); return end

    local vendors = {
        {idx=3, name="ISO 17981:2024 --- CubeSat interface", cite="\\cite{iso_17981_page, iso_17981_preview}"},
        {idx=4, name="LibreCube Board Specification", cite="\\cite{librecube_board_spec}"},
        {idx=5, name="Pumpkin CubeSat Kit Bus / MBM2", cite="\\cite{pumpkin_mbm2_ds}"},
        {idx=6, name="EnduroSat OBC Type I/II --- legacy model", cite="\\cite{endurosat_type1_ds, endurosat_type2_manual}"},
        {idx=7, name="Simera Sense TriScape100 Control Electronics", cite="\\cite{simera_triscape100_icd}"}
    }

    tex.print("\\begin{longtable}{|p{5.5cm}|p{14.0cm}|p{3.5cm}|}")
    tex.print("\\caption{PC/104 Pinout Survey Across Standards and Commercial Platforms} \\label{tab:appendix_c_pc104_pinouts} \\\\ \\hline")
    tex.print("\\textbf{Specification / Platform} & \\textbf{PC/104 Pinout} & \\textbf{Source} \\\\ \\hline")
    tex.print("\\endfirsthead")
    tex.print("\\caption[]{PC/104 Pinout Survey Across Standards and Commercial Platforms (Continued)} \\\\ \\hline")
    tex.print("\\textbf{Specification / Platform} & \\textbf{PC/104 Pinout} & \\textbf{Source} \\\\ \\hline")
    tex.print("\\endhead")
    tex.print("\\hline")
    tex.print("\\endfoot")

    for _, v in ipairs(vendors) do
        local desc_groups = {H1={}, H2={}}
        local desc_order = {H1={}, H2={}}
        
        for _, row in ipairs(data) do
            local conn = row[1]
            local pin = tonumber(row[2])
            local desc = sanitize(row[v.idx] or "")
            if desc ~= "" then
                if not desc_groups[conn][desc] then
                    desc_groups[conn][desc] = {}
                    table.insert(desc_order[conn], desc)
                end
                table.insert(desc_groups[conn][desc], pin)
            end
        end

        local groups = {}
        for _, conn in ipairs({"H1", "H2"}) do
            for _, desc in ipairs(desc_order[conn]) do
                local pins = desc_groups[conn][desc]
                table.sort(pins)
                
                local pin_str_parts = {}
                local i = 1
                while i <= #pins do
                    local start_pin = pins[i]
                    local end_pin = start_pin
                    while i < #pins and pins[i+1] == pins[i] + 1 do
                        i = i + 1
                        end_pin = pins[i]
                    end
                    if end_pin - start_pin >= 2 then
                        table.insert(pin_str_parts, start_pin .. "\\dots" .. end_pin)
                    elseif end_pin > start_pin then
                        table.insert(pin_str_parts, start_pin .. "/" .. end_pin)
                    else
                        table.insert(pin_str_parts, start_pin)
                    end
                    i = i + 1
                end
                local pin_str = conn .. "-" .. table.concat(pin_str_parts, "/")
                table.insert(groups, pin_str .. " --- " .. desc)
            end
        end

        local cell2 = table.concat(groups, " \\newline\n    ")
        
        tex.print(string.format("\\textbf{%s} &", v.name))
        tex.print(cell2 .. " &")
        tex.print(v.cite .. " \\\\ \\hline")
    end

    tex.print("\\end{longtable}")
end

function pc104.gen_figure1()
    local data = read_csv("pc104.csv")
    if not data then tex.sprint("Error reading pc104.csv"); return end

    local vendors = {
        {idx=3, id="iso", color="blue!80!black"},
        {idx=4, id="lc",  color="green!60!black"},
        {idx=5, id="pk",  color="orange!90!black"},
        {idx=6, id="es",  color="purple!80!black"},
        {idx=7, id="si",  color="teal!80!black"}
    }

    local function process_pin(conn, pin)
        local owners = {}
        for _, v in ipairs(vendors) do
            local row_idx = 1
            for i, r in ipairs(data) do
                if r[1] == conn and tonumber(r[2]) == pin then
                    row_idx = i
                    break
                end
            end
            local desc = sanitize(data[row_idx][v.idx] or "")
            if desc ~= "" then
                table.insert(owners, {v=v, desc=desc})
            end
        end
        return owners
    end
    
    tex.print("\\begin{tikzpicture}[scale=0.29, every node/.style={inner sep=0.5pt}]")

    local function draw_header(conn_name, xshift, x_col1, x_col2)
        tex.print(string.format("\\begin{scope}[xshift=%fcm]", xshift))
        
        local cx = (x_col1 + x_col2) / 2
        tex.print(string.format("\\fill[gray!20, rounded corners=2pt] (%f, 31.5) rectangle (%f, -16.5);", x_col1 - 1.0, x_col2 + 1.0))
        tex.print(string.format("\\draw[thick, gray!80, rounded corners=2pt] (%f, 31.5) rectangle (%f, -16.5);", x_col1 - 1.0, x_col2 + 1.0))
        tex.print(string.format("\\node[font=\\sffamily\\bfseries\\color{blue}] at (%f, 32.5) {%s};", cx, conn_name))

        for r=0, 25 do
            local ypos = 30.0 - r * 1.8
            local ymin = ypos - 0.55
            local ymax = ypos + 0.55
            local podd = r*2 + 1
            local peven = r*2 + 2

            for col=1, 2 do
                local pnum = (col == 1) and podd or peven
                local owners = process_pin(conn_name, pnum)
                
                local xc = (col == 1) and x_col1 or x_col2
                local xmin = xc - 0.55
                local xmax = xc + 0.55
                
                if #owners > 0 then
                    local xmid = (xmin + xmax) / 2
                    local ymid = ypos
                    if #owners == 1 then
                        tex.print(string.format("\\fill[%s] (%f, %f) rectangle (%f, %f);", owners[1].v.color, xmin, ymin, xmax, ymax))
                    elseif #owners == 2 then
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[1].v.color, xmin, ymax, xmax, ymax, xmax, ymin))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[2].v.color, xmax, ymin, xmin, ymin, xmin, ymax))
                    elseif #owners == 3 then
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[1].v.color, xmin, ymax, xmax, ymax, xmid, ymid))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[2].v.color, xmax, ymax, xmax, ymin, xmid, ymid))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[3].v.color, xmax, ymin, xmin, ymin, xmin, ymax)) 
                    elseif #owners >= 4 then
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[1].v.color, xmin, ymax, xmax, ymax, xmid, ymid))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[2].v.color, xmax, ymax, xmax, ymin, xmid, ymid))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[3].v.color, xmax, ymin, xmin, ymin, xmid, ymid))
                        tex.print(string.format("\\fill[%s] (%f, %f) -- (%f, %f) -- (%f, %f) -- cycle;", owners[4].v.color, xmin, ymin, xmin, ymax, xmid, ymid))
                    end
                else
                    tex.print(string.format("\\fill[gray!50] (%f, %f) rectangle (%f, %f);", xmin, ymin, xmax, ymax))
                end
                
                tex.print(string.format("\\draw[black, thick] (%f, %f) rectangle (%f, %f);", xmin, ymin, xmax, ymax))
                tex.print(string.format("\\node[white, font=\\bfseries\\scriptsize\\ttfamily] at (%f, %f) {%d};", xc, ypos, pnum))

                if #owners > 0 then
                    local callout_color = owners[1].v.color
                    local label_parts = {}
                    for _, o in ipairs(owners) do
                        table.insert(label_parts, string.format("{\\color{%s}%s}", o.v.color, o.desc))
                    end
                    local label_str = table.concat(label_parts, " / ")
                    
                    if col == 1 then
                        local endx = xmin - 1.25
                        local textx = endx - 1.35
                        tex.print(string.format("\\draw[thick, %s] (%f, %f) -- (%f, %f);", callout_color, xmin, ypos, endx, ypos))
                        tex.print(string.format("\\draw[dotted, thick, %s] (%f, %f) -- (%f, %f) node[left, font=\\tiny\\bfseries\\ttfamily] {%s};", callout_color, endx, ypos, textx, ypos, label_str))
                    else
                        local endx = xmax + 1.25
                        local textx = endx + 1.35
                        tex.print(string.format("\\draw[thick, %s] (%f, %f) -- (%f, %f);", callout_color, xmax, ypos, endx, ypos))
                        tex.print(string.format("\\draw[dotted, thick, %s] (%f, %f) -- (%f, %f) node[right, font=\\tiny\\bfseries\\ttfamily] {%s};", callout_color, endx, ypos, textx, ypos, label_str))
                    end
                end
            end
        end
        tex.print("\\end{scope}")
    end

    draw_header("H1", -3.5, -11.4, -9.6)
    draw_header("H2", 3.5, 9.6, 11.4)

    tex.print("\\begin{scope}[yshift=-21cm]")
    tex.print("\\node[anchor=north] at (0,0) {")
    tex.print("\\begin{tabular}{ll}")
    tex.print("\\textcolor{blue!80!black}{\\rule{10pt}{10pt}} ISO 17981:2024 & \\textcolor{green!60!black}{\\rule{10pt}{10pt}} LibreCube Spec \\\\")
    tex.print("\\textcolor{orange!90!black}{\\rule{10pt}{10pt}} Pumpkin MBM2 & \\textcolor{purple!80!black}{\\rule{10pt}{10pt}} EnduroSat Legacy \\\\")
    tex.print("\\multicolumn{2}{c}{\\textcolor{teal!80!black}{\\rule{10pt}{10pt}} Simera TriScape100}")
    tex.print("\\end{tabular}")
    tex.print("};")
    tex.print("\\end{scope}")
    
    tex.print("\\end{tikzpicture}")
end

return pc104
