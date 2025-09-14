local M = {}

local world_template = "#%s"

math.randomseed(os.time())

local prelude_conversation = {
    { ["character"] = "BUNNY",  ["text"] = "Hi Froggy! Lets go to the park for a picnic." },
    { ["character"] = "FROGGY", ["text"] = "Hi Bunny!, Sounds fun! What should we bring?" },
    { ["character"] = "BUNNY",  ["text"] = "How about some snacks? I love playing games too!" },
    { ["character"] = "NONE",   ["text"] = "At the park..." },
    { ["character"] = "FROGGY", ["text"] = "Yum... Yum..." },
    { ["character"] = "BUNNY",  ["text"] = "These snacks are delicious!" },
    { ["character"] = "NONE",   ["text"] = "Bunny opens cooler..." },
    { ["character"] = "BUNNY",  ["text"] = "What!!! Just one icecream left?" },
    { ["character"] = "FROGGY", ["text"] = "Aww... I was looking forward to that." },
    { ["character"] = "BUNNY",  ["text"] = "How about we play a game to decide who gets the icecream?" },
    { ["character"] = "FROGGY", ["text"] = "Great idea! Let's play Rock, Paper, Scissors!" },
    { ["character"] = "BUNNY",  ["text"] = "Great! Let's play!" },
}

function M.load_world(name)
    M.game_state.previous_level = M.game_state.level
    M.game_state.level = name
    msg.post(world_template:format(name), "load")
    msg.post(world_template:format(M.game_state.previous_level), "disable")
    msg.post(world_template:format(M.game_state.previous_level), "final")
    msg.post(world_template:format(M.game_state.previous_level), "unload")
end

-- Game state object
M.game_state = {
    player_choice = nil,
    enemy_choice = nil,
    result = nil,
    round = 1,
    player_wins = 0,
    enemy_wins = 0,
    draws = 0,
    total_rounds = 3,
    total_plays_per_round = 3,
    current_play = 1,
    level = "loader",
    previous_level = nil,
    conversation_index = 0,
}

function M.get_current_conversation()
    M.game_state.conversation_index = M.game_state.conversation_index + 1
    return prelude_conversation[M.game_state.conversation_index]
end

function M.is_conversation_done()
    return M.game_state.conversation_index >= #prelude_conversation
end

-- Helper functions
local function random_pick()
    local choices = { "ROCK", "PAPER", "SCISSORS" }
    return choices[math.random(#choices)]
end

local function determine_winner(player_choice, enemy_choice)
    if player_choice == enemy_choice then
        return "DRAW"
    elseif (player_choice == "ROCK" and enemy_choice == "SCISSORS") or
        (player_choice == "PAPER" and enemy_choice == "ROCK") or
        (player_choice == "SCISSORS" and enemy_choice == "PAPER") then
        return "PLAYER"
    else
        return "ENEMY"
    end
end

-- Game state management functions
function M.reset_game_state()
    M.game_state = {
        level = 'loader',
        previous_level = nil,
        player_choice = nil,
        enemy_choice = nil,
        result = nil,
        round = 1,
        player_wins = 0,
        enemy_wins = 0,
        draws = 0,
        total_rounds = 3,
        total_plays_per_round = 3,
        current_play = 1,
        conversation_index = 0,
    }
end

function M.generate_enemy_choice()
    M.game_state.enemy_choice = random_pick()
end

function M.handle_player_choice(player_choice)
    M.game_state.player_choice = player_choice
    M.generate_enemy_choice()
    local winner = determine_winner(M.game_state.player_choice, M.game_state.enemy_choice)
    if winner == "PLAYER" then
        M.game_state.result = 'WON'
        M.game_state.player_wins = M.game_state.player_wins + 1
    elseif winner == "ENEMY" then
        M.game_state.result = 'LOST'
        M.game_state.enemy_wins = M.game_state.enemy_wins + 1
    else
        M.game_state.result = 'DRAW'
        M.game_state.draws = M.game_state.draws + 1
    end
    M.game_state.current_play = M.game_state.current_play + 1
end

function M.calculate_final_result()
    if M.game_state.player_wins > M.game_state.enemy_wins then
        M.game_state.result = 'WON'
    elseif M.game_state.player_wins < M.game_state.enemy_wins then
        M.game_state.result = 'LOST'
    else
        M.game_state.result = 'DRAW'
    end
end

function M.is_round_over()
    return M.game_state.current_play > M.game_state.total_plays_per_round
end

function M.is_final_round()
    return M.game_state.round >= M.game_state.total_rounds
end

function M.advance_to_next_round()
    M.game_state.round = M.game_state.round + 1
    M.game_state.current_play = 1
    M.game_state.player_choice = nil
    M.game_state.enemy_choice = nil
    M.game_state.result = nil
end

function M.update_state(updates)
    if type(updates) ~= "table" then
        error("update_state expects a table of key-value pairs")
        return
    end

    for key, value in pairs(updates) do
        if M.game_state[key] ~= nil then
            M.game_state[key] = value
        else
            print("Warning: Attempted to update unknown game state property: " .. tostring(key))
        end
    end
end

-- Utility function to set background color
function M.set_background_color(hex_color)
    local color
    if hex_color == "FFEFC3" then
        -- Default cream/beige color
        color = vmath.vector4(1.0, 0.937, 0.765, 1.0)
    else
        -- You can extend this to parse other hex colors if needed
        color = vmath.vector4(1.0, 0.937, 0.765, 1.0)
    end
    msg.post("@render:", "clear_color", { color = color })
end

M.handle_messages = function(message_id, message, sender)
    if message_id == hash("proxy_loaded") then
        msg.post(sender, "init")
        msg.post(sender, "enable")
    elseif message_id == hash("go_to_main_menu") then
        M.load_world("main_menu")
    elseif message_id == hash("go_to_round") then
        M.load_world("round")
    elseif message_id == hash("go_to_results") then
        M.load_world("results")
    elseif message_id == hash("go_to_main") then
        M.load_world("main")
    elseif message_id == hash("go_to_prelude") then
        M.load_world("prelude")
    end
end

return M
