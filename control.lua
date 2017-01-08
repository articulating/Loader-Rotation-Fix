local offsets = {
    [defines.direction.north] = {0, -1.5},
    [defines.direction.south] = {0, 1.5},
    [defines.direction.east] = {1.5, 0},
    [defines.direction.west] = {-1.5, 0}
}
function add_position(position, x, y)
    return {position.x + (x or 0), position.y + (y or 0)}
end

function check_loader(entity, e)
    local name, position, surface, force, direction,loader_type,last_user = entity.name, entity.position, entity.surface, entity.force, entity.direction, entity.loader_type, entity.last_user
    entity.destroy()
    local output_offset = offsets[direction]
    local output_position = add_position(position, output_offset[1], output_offset[2])
    local output_entity = surface.find_entities_filtered{position=output_position, force=force}[1]
    local inverted_direction = (direction + 4) % 8
    local changed = false
    if output_entity and output_entity.valid and output_entity.has_flag("player-creation") then
        if (output_entity.type == "transport-belt" or (output_entity.type == "underground-belt" and output_entity.belt_to_ground_type ~= "input")) and output_entity.direction == inverted_direction then
            direction = (direction + 4) % 8
            loader_type = "input"
            changed = true
        elseif output_entity.type ~= "transport-belt" and output_entity.type~="underground-belt" and output_entity.type~="loader" then
            loader_type = "input"
            changed = true
        end
    end
    if not changed then
        local input_offset = offsets[inverted_direction]
        local input_position = add_position(position, input_offset[1], input_offset[2])
        local input_entity = surface.find_entities_filtered{position=input_position, force=force}[1]
        if input_entity and input_entity.valid and input_entity.has_flag("player-creation") then
            if (input_entity.type == "transport-belt" or (input_entity.type == "underground-belt" and input_entity.belt_to_ground_type ~= "input"))  then
                if input_entity.direction == inverted_direction then
                    direction = (direction + 4) % 8
                elseif input_entity.type ~= "loader" then
                    loader_type = "input"
                end
                changed = true
            end
        end
    end
    local new = surface.create_entity{name=name, position=position, force=force, direction=direction,type=loader_type}
    if new and new.valid then
        new.last_user = last_user
        game.raise_event(defines.events.on_built_entity, {name=defines.events.on_built_entity, tick=game.tick, corrected_loader=true, player_index=e.player_index, created_entity=new})
    end
end

script.on_event(defines.events.on_built_entity, function(e)
    if e.corrected_loader then return end
    local entity = e.created_entity
    if entity.valid then
        if entity.type == "loader" then
            check_loader(entity, e)
        else
            local position=entity.position
            local box = entity.prototype.selection_box
            local checkArea = {{position.x+box.left_top.x-1, position.y+box.left_top.y-1}, {position.x+box.right_bottom.x+1, position.y+box.right_bottom.y+1}}
            for _, loader in pairs(entity.surface.find_entities_filtered{type="loader", area=checkArea}) do
                check_loader(loader, e)
            end
        end
    end
end)
