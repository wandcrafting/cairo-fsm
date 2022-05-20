%lang starknet

struct Guard:
end

struct Action:
end
#event = action    -- could be action of other agents, part of dynamics of world

struct State:
    member entry_action: Action
    member activity : Action
    member exit_action: Action
end

struct Transition:
    member action : Action
    member guard : Guard
end

@storage_var
func states(name : felt) -> (state : State):
end

#use these name in states storage var
@storage_var
func init_state() -> (name : felt): 
end

@storage_var
func final_state() -> (name : felt): 
end

@storage_var
func transition(from_name : felt, to_name : felt) -> (transition : Transition):
end

