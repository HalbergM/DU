--[[
    Pure Status Display

    Refactored thanks to Dorian Gray

    1. Copy & paste this script into your Programming Board, into slot "unit" and filter "start()"
    2. Add a "stop()" filter and enter "display1.clear()" into the Lua editor for this filter
    3. Add a "tick()" filter and enter the parameter "updateTick, so "tick(updateTick)". In the Lua editor for the filter enter "processTick()"
    4. Link the core this setup is placed on to your Programming Board and rename the slot to "core"
    5. Link 1 screen to your Programming Board, preferably S or larger, and name the slot "display1".
    6. Rename your pure storage boxes you want this script to observe. Pures must be named "Pure <purename>", e.g. "Pure Alumnium". Any wrongly named container will not be observed.You can rename the searchString under Advanced->Edit Lua Parameters, You MUST include spaces not in the actual substance name. You can have more than one container for a single substance, if you have e.g. three large containers for Aluminium, name all of them "Pure Aluminium". The script does not support multiple substances in one container.
    7. On your Programming Board choose Advanced->Edit Lua Parameters and enter your Container Proficiency Bonus in percent (0 to 50) and your Container Optimization Bonus in percent (0-25)
    8. Activate the Programming Board.
]]

unit.hide()
display1.activate()

function round(number,decimals)
    local power = 10^decimals
    return math.floor((number/1000) * power) / power
end 

PlayerContainerProficiency = 30 --export Your Container Proficiency bonus in total percent (Skills->Mining and Inventory->Inventory Manager)
PlayerContainerOptimization = 0 --export Your Container Optimization bonus in total percent (Skills->Mining and Inventory->Stock Control)
MinimumYellowPercent = 25 --export At which percent level do you want bars to be drawn in yellow (not red anymore)
MinimumGreenPercent = 50 --export At which percent level do you want bars to be drawn in green (not yellow anymore)
searchString = "Pure " --export Your identifier for Pure Storage Containers (e.g. "Pure Aluminium"). Include the spaces if you change this!

function processTick()

    elementsIds = core.getElementIdList()
    outputData = {}

     substanceMass = {
        Oxygen=1;
        Hydrogen=0.07;
        Aluminium=2.7;
        Carbon=2.27;
        Silicon=2.33;
        Iron=7.85;
        Calcium=1.55;
        Chromium=7.19;
        Copper=8.96;
        Sodium=0.97;
        Lithium=0.53;
        Nickel=8.91;
        Silver=10.49;
        Sulfur=1.82;
        Cobalt=8.9;
        Fluorine=1.7;
        Gold=19.3;
        Scandium=2.98;
        Manganese=7.21;
        Niobium=8.57;
        Titanium=4.51;
        Vanadium=6;
    }

    function processSubstanceContainer(_id)
        local ContainerName = core.getElementNameById(_id)
        local ContainerTotalMass = core.getElementMassById(_id)
        local ContainerMaxHP = core.getElementMaxHitPointsById(_id)
        SubstanceName=string.gsub(ContainerName, searchString, "")

        if SubstanceName~="" then
            SubstanceSingleMass=substanceMass[SubstanceName]
            if SubstanceSingleMass~=nil then
                if ContainerMaxHP > 49 and ContainerMaxHP <=123 then
                    ContainerSelfMass = 0
                    CapacityForSubstance = 0
                elseif ContainerMaxHP > 123 and ContainerMaxHP <= 998 then
                    ContainerSelfMass = 229.09
                    CapacityForSubstance = (1000+(1000*(PlayerContainerProficiency/100)))
                elseif ContainerMaxHP > 998 and ContainerMaxHP <= 7996 then
                    ContainerSelfMass = 1280
                    CapacityForSubstance = (8000+(8000*(PlayerContainerProficiency/100)))
                elseif ContainerMaxHP > 7996 and ContainerMaxHP <= 17315 then
                    ContainerSelfMass = 7420
                    CapacityForSubstance = (64000+(64000*(PlayerContainerProficiency/100)))
                elseif ContainerMaxHP > 17315 then
                    ContainerSelfMass = 14840
                    CapacityForSubstance = (128000+(128000*(PlayerContainerProficiency/100)))
                end

                local ContentMass=ContainerTotalMass-ContainerSelfMass
                local OptimizedContentMass = ContentMass+ContentMass*(PlayerContainerOptimization/100)
                local ContentAmount = (OptimizedContentMass/SubstanceSingleMass)

                if outputData[SubstanceName]~=nil then
                    outputData[SubstanceName] = {
                        name = SubstanceName;
                        amount = outputData[SubstanceName]["amount"]+ContentAmount;
                        capacity = outputData[SubstanceName]["capacity"]+CapacityForSubstance;
                    }
                else
                    local entry = {
                        name = SubstanceName;
                        amount = ContentAmount;
                        capacity = CapacityForSubstance;
                    }
                    outputData[SubstanceName]=entry
                end
            end
        end
    end

    for i = 1, #elementsIds do
        if string.match(core.getElementTypeById(elementsIds[i]), "ontainer") and string.match(core.getElementNameById(elementsIds[i]), searchString) then
            processSubstanceContainer(elementsIds[i])
        end
    end

    function BarGraph(percent)
        if percent <= 0 then barcolour = "red"
        elseif percent > 0 and percent <= MinimumYellowPercent then barcolour = "red"
        elseif percent > MinimumYellowPercent and percent <= MinimumGreenPercent then barcolour = "orange"
        elseif percent > MinimumGreenPercent then  barcolour = "green"
        else  barcolour = "green"
        end 
        return "<td class=\"bar\" valign=top>"..
                    "<svg>"..
                        "<rect x=\"0\" y=\"1\" rx=\"4\" ry=\"4\" height=\"2.2vw\" width=\"17.2vw\" stroke=\"white\" stroke-width=\"1\" rx=\"0\" />"..
                        "<rect x=\"1\" y=\"2\" rx=\"3\" ry=\"3\" height=\"2.1vw\" width=\"" .. (17/100*percent) .. "vw\"  fill=\"" .. barcolour .. "\" opacity=\"1.0\" rx=\"0\"/>"..
                        "<text x=\"2\" y=\"20\" fill=\"white\" text-align=\"center\" margin-left=\"3\">" .. string.format("%02.1f", percent) .. "%</text>"..
                    "</svg>"..
                "</td>"        
    end

    function AddHTMLEntry(_id1, _id2)
        local id1amount = 0
        local id2amount = 0
        local id1percent = 0
        local id2percent = 0
        if outputData[_id1]~=nil then 
            id1amount = outputData[_id1]["amount"]
            id1percent = (outputData[_id1]["amount"])/outputData[_id1]["capacity"]*100
        end
        if id1amount >= 1000000 then
            id1amount = id1amount/1000000
            id1unit = "ML"
        else
            id1amount = id1amount/1000
            id1unit = "KL"
        end
        if outputData[_id2]~=nil then
            id2amount = outputData[_id2]["amount"]
            id2percent = (outputData[_id2]["amount"])/outputData[_id2]["capacity"]*100
        end
        if id2amount >= 1000000 then
            id2amount = id2amount/1000000
            id2unit = "ML"
        else
            id2amount = id2amount/1000
            id2unit = "KL"
        end
        resHTML =
            [[<tr>
                <th align=right>]].._id1..[[:&nbsp;</th>
                <th align=right>]]..string.format("%02.1f", id1amount)..[[&nbsp;</th>
                <th align=left>]]..id1unit..[[&nbsp;</th>
                ]]..BarGraph(id1percent)..[[
                <th style="background-color: blue;">&nbsp;</th>
                <th align=right>]].._id2..[[:&nbsp;</th>
                <th align=right>]]..string.format("%02.1f", id2amount)..[[&nbsp;</th>
                <th align=left>]]..id2unit..[[&nbsp;</th>
                ]]..BarGraph(id2percent)..[[
            </tr>]]
        return resHTML
    end

    htmlHeader = [[<head><style>.bar { text-align: left; vertical-align: top; font-family:Arial; border-radius: 0 0em 0em 0; }</style></head>]]
    d1 = [[<div class="bootstrap" style="text-align:left; vertical-align: text-top;">]]
    d2 = [[<span style="text-transform: capitalize; font-family:Arial; font-size: 2.5em;">&nbsp;]]
    t1 = [[&nbsp;</span>
        <table style="text-transform: capitalize; font-family:Arial; font-size: 2em; table-layout: auto; width: 100vw;">
        <tr style="width:100vw; background-color: blue; color: white;">]]
    t2 = [[ <th style="width:17vw; text-align:right;">Type</th>
            <th style="width:10vw; text-align:center;">Vol</th>
            <th style="width:5vw;">&nbsp;</th>
            <th style="width:18vw;text-align:left;">Levels</th>
            <th style="background-color: blue;">&nbsp;</th>
            <th style="width:17vw; text-align:right;">Type</th>
            <th style="width:10vw; text-align:center;">Vol</th>
            <th style="width:5vw;">&nbsp;</th>
            <th style="width:18vw;text-align:left;">Levels</th>
        </tr>]]
    c1 = [[</table></div> ]]

    if display1 then
        html=htmlHeader
        html=html..d1..d2.."Tier 1"..t1..t2
        html=html..AddHTMLEntry("Aluminium", "Carbon")
        html=html..AddHTMLEntry("Iron", "Silicon")
        html=html..AddHTMLEntry("Hydrogen", "Oxygen")

        html=html..t1..d2.."Tier 2"..t1..t2
        html=html..AddHTMLEntry("Sodium", "Copper")
        html=html..AddHTMLEntry("Calcium", "Chromium")

        html=html..t1..d2.."Tier 3"..t1..t2
        html=html..AddHTMLEntry("Lithium", "Nickel")
        html=html..AddHTMLEntry("Sulfur", "Silver")

        html=html..t1..d2.."Tier 4"..t1..t2
        html=html..AddHTMLEntry("Cobalt", "Fluorine")
        html=html..AddHTMLEntry("Gold", "Scandium")

        html=html..t1..d2.."Tier 5"..t1..t2
        html=html..AddHTMLEntry("Manganese", "Niobium")
        html=html..AddHTMLEntry("Titanium", "Vanadium")
        html=html..c1
        display1.setHTML(html)
    end
end

processTick()
unit.setTimer('updateTick', 5)