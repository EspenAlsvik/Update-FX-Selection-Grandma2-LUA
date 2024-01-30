-- Hey and welcome to my Update FX-Selection Plugin

-- before using make sure your group names are correct formated and with captital letters etc


-- Wash, Wash Sym, LX1 Wash, LX2 Wash, LX3 Wash (for original Group. Same for Spot, Beam, Blinder and Strobe)

-- Wash Clone, Wash Clone Sym, LX1 Wash Clone, LX2 Wash Clone, LX3 Wash Clone (For Clone Groups)


--Plugin: Update FX-Selection
--Made By: Espen Alsvik
-----------------------------------------------------------------------------------------------------------------------------


gma = gma

-- Prompt for user input
local function promptForGroupType()
    return gma.textinput("Enter Group Type", "Wash, Spot, Beam, Strobe, Blinder")
end

-- Check if a group exists
local function groupExists(grp)
    local groupInfo = gma.show.getobj.handle('Group ' .. grp)
    return groupInfo ~= nil
end

-- Export a group to a file and return the list of fixtures
local function exportGroup(grp, filename)
    gma.cmd('Export Group ' .. grp .. ' \"' .. filename .. '\" /o') -- create temporary file
    local groupList = {}
    for line in io.lines(gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/' .. filename) do
        if line:find('Subfixture ') then
            local indices = {line:find('\"%d+\"')} -- find points of quotation marks
            indices[1], indices[2] = indices[1] + 1, indices[2] - 1 -- move reference points to first and last characters inside those marks
            local fixtureNumber = tonumber(line:sub(indices[1], indices[2]))
            table.insert(groupList, fixtureNumber)
        end
    end
    os.remove(gma.show.getvar('PATH') .. '/' .. 'importexport' .. '/' .. filename) -- delete temporary file
    return groupList
end

-- Check if the fixture list is non-consecutive
local function isNonConsecutive(list)
    for i = 1, #list - 1 do
        if list[i] + 1 ~= list[i + 1] then
            return true
        end
    end
    return false
end

-- Check if two lists are equal
local function areListsEqual(list1, list2)
    local sortedList1 = {}
    local sortedList2 = {}
    for i, v in ipairs(list1) do
        table.insert(sortedList1, v)
    end
    for i, v in ipairs(list2) do
        table.insert(sortedList2, v)
    end

    if #sortedList1 ~= #sortedList2 then
        return false
    end
    table.sort(sortedList1)
    table.sort(sortedList2)
    for i = 1, #sortedList1 do
        if sortedList1[i] ~= sortedList2[i] then
            return false
        end
    end
    return true
end

-- Store effect if the fixture groups match
local function storeEffectIfMatch(groupOriginal, groupClone, fx)
    if groupExists('\"' .. groupOriginal .. '\"') then
        local groupList1 = exportGroup(1000, 'tempfile1.xml')
        local groupList2 = exportGroup('\"' .. groupOriginal .. '\"', 'tempfile2.xml')
        local match = areListsEqual(groupList1, groupList2)
        local nonConsecutive = isNonConsecutive(groupList1)

        if match then
            gma.echo("Group 1000 matches Group " .. groupOriginal)
            if nonConsecutive and (groupOriginal == "Wash" or groupOriginal == "Spot" or groupOriginal == "Beam" or groupOriginal == "Strobe" or groupOriginal == "Blinder") then
                groupClone = groupClone .. " Sym"
            end
            gma.cmd('clear clear clear; group "' .. groupClone .. '"; group "' .. groupClone .. '"; store /O effect 1.' .. fx .. '.1')
        else
            gma.echo("Group 1000 does not match Group " .. groupOriginal)
        end
    else
        gma.echo("Group " .. groupOriginal .. " does not exist")
    end
end

-- Main function to update fixture functions
local function updateffx()
    local groupType = promptForGroupType()
    local baseGroups = {
        Wash = "Wash",
        Spot = "Spot",
        Beam = "Beam",
        Strobe = "Strobe",
        Blinder = "Blinder"
    }

    local selectedGroupPrefix = baseGroups[groupType]
    if not selectedGroupPrefix then
        gma.echo("Invalid group type entered")
        return
    end

    local groupsToCheck = {}
    groupsToCheck[selectedGroupPrefix] = selectedGroupPrefix .. " Clone"
    for i = 1, 3 do
        groupsToCheck["LX" .. i .. " " .. selectedGroupPrefix] = "LX" .. i .. " " .. selectedGroupPrefix .. " Clone"
    end

    for fx = 1, 10000 do
        local fxexist = gma.show.getobj.handle("effect " .. fx)
        if fxexist ~= nil then
            gma.cmd("clear clear clear;Delete Group 1000; SelFix Effect " .. fx .. "; Store /o Group 1000")
            
            -- Checking the effects for each group
            for originalGroup, cloneGroup in pairs(groupsToCheck) do
                storeEffectIfMatch(originalGroup, cloneGroup, fx)
            end
        end
     end
    gma.cmd ("clear clear clear")
end



return updateffx
