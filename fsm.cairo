%lang starknet

struct Guard:
end

struct Action:
end
#event = action    -- could be action of other agents, part of dynamics of world

struct State:
    member start_bool : felt #1 if true
    member final_bool : felt #1 if true
    member entry_action: Action
    member activity : Action
    member exit_action: Action
end

struct Transition:
    member init_state : State
    member final_state : State
    member action : Action
    member guard : Guard
end

@storage_var
func states(name : felt) -> (state : State):
end

@storage_var
func transition(init_state : State, final_state : State) -> (transition : Transition):
end

#struct machine

#const Machine = machine(init: off)

#machine.state

#machine.transition(state, 'switch')

#machine.transi

