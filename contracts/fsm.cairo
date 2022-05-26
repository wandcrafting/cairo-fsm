%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal

################################################################################
# Types
################################################################################

struct Action:
    member name : felt
    member external : felt # if 1, this action is initiated by environment. if 0, this action is initiated by another agent.
end

struct State:
    member entry : Action
    member do : Action
    member exit : Action
end

struct Transition:
    member action : Action
    member condition : felt # if 1, this transition is enabled. if 0, this transition is disabled.
end

################################################################################
# Storage Vars
################################################################################

@storage_var
func states (name : felt) -> (state : State):
end

@storage_var
func init_state() -> (name : felt): 
end

@storage_var
func final_state() -> (name : felt): 
end

@storage_var
func current_state() -> (name : felt): 
end

#event can be an external action (give a name, and external bool = 0), or entry/do/exit action, or a transition action
@storage_var
func transitions(from_name : felt, to_name : felt, event : Action) -> (transition : Transition):
end

################################################################################
# Adding, Updating, Removing, and Reading States
################################################################################

namespace state_access:

    func add_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt, do_name : felt, exit_name : felt) -> ():
        #check that state doesn't already exist for this name
        let entry = Action(name=entry_name, external=0)
        let do = Action(name=do_name, external=0)
        let exit = Action(name=exit_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    func update_state_entry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt) -> ():
        #check that state already exists for this name
        let (actions) = states.read(name)
        let do = actions.do
        let exit = actions.exit
        let entry = Action(name=entry_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    func update_state_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, do_name : felt) -> ():
        #check that state already exists for this name -- find state, go to its action and check the action name, it should be non-0
        let (actions) = states.read(name)
        let entry = actions.entry
        let exit = actions.exit
        let do = Action(name=do_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    func update_state_exit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, exit_name : felt) -> ():
        #check that state already exists for this name
        let (actions) = states.read(name)
        let entry = actions.entry
        let do = actions.do
        let exit = Action(name=exit_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    func remove_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        #check that state already exists for this name
        let entry = Action(name=0, external=0)
        let do = Action(name=0, external=0)
        let exit = Action(name=0, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    func get_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (state : State):
        let (state) = states.read(name)
        ret 
    end

end













func set_init_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
    #%TODO: check if state exists for given name
    # let (check) = states.read(name)
    # with_attr error_message("Initial and Final states can't be the same."):
    #     assert_not_zero(check)
    # end
    let (final) = final_state.read()
    with_attr error_message("Initial and Final states can't be the same."):
        assert_not_equal(name, final)
    end
    init_state.write(name)
    let (current) = current_state.read()
    if current == 0:
        current_state.write(name)
    end
    ret 
end

func set_final_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
    #%TODO: check if state exists for given name
    let (init) = init_state.read()
    with_attr error_message("Initial and Final states can't be the same."):
        assert_not_equal(name, init)
    end
    final_state.write(name)
    ret 
end

func set_curr_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
    #%TODO: check if state exists for given name
    current_state.write(name)
    let (_, do, _) = get_state_actions(name)
    #TODO: emit that action event was executed
    ret 
end

func add_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action, trans_action_name : felt, condition : felt) -> ():
    #%TODO: check if state exists for from_name, to_name
    let transition_action = Action(name=trans_action_name, external=0)
    let transition = Transition(transition_action, condition)
    transitions.write(from_name, to_name, event, transition)
    ret
end

################################################################################
# Read from Storage Vars
################################################################################

func get_init_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : State):
    let (name) = init_state.read()
    let (state) = states.read(name)
    ret
end

func get_final_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : State):
    let (name) = final_state.read()
    let (state) = states.read(name)
    ret
end

func get_current_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (state : State):
    let (name) = current_state.read()
    let (state) = states.read(name)
    ret
end



func get_state_actions {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (entry : Action, do : Action, exit : Action):
    let (state) = states.read(name)
    let entry = state.entry
    let do = state.do
    let exit = state.exit
    ret
end

func get_transition_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action) -> (action : Action):
    let (transition) = transitions.read(from_name, to_name, event)
    let action = transition.action
    ret
end

func execute_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action):
    let (curr) = current_state.read()
    if from_name == curr:
        let (transition) = transitions.read(from_name, to_name, event)
        #TODO: check that transition exists
        let (_, _, exit) = get_state_actions(curr)
        let (entry, _, _) = get_state_actions(curr)
        #TODO: emit that action events were executed - exit, transition.action, entry
        current_state.write(to_name)
        end
    ret
end