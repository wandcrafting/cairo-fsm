%lang starknet

struct Guard:
end

struct Action:
end
#event = action    -- could be action of other agents, part of dynamics of world


struct Transition:
    member init_state : State
    member final_state : State
    member action : Action
    member guard : Guard
end

struct State:
    member name : felt

    member start? : felt #1 if true
    member final? : felt #1 if true

    member entry_action: Action
    member activity : Action
    member exit_action: Action





#struct machine

#const Machine = machine(init: off)

#machine.state

#machine.transition(state, 'switch')

#machine.transi

