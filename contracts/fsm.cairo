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
# Functions
################################################################################

namespace states_storage:
    @external
    func add_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt, do_name : felt, exit_name : felt) -> ():
        states_internal.check_state_non_existence(name)
        assert_not_zero(name)
        let entry = Action(name=entry_name, external=0)
        let do = Action(name=do_name, external=0)
        let exit = Action(name=exit_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func update_state_entry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt) -> ():
        states_internal.check_state_existence(name)
        let (actions) = states.read(name)
        let do = actions.do
        let exit = actions.exit
        let entry = Action(name=entry_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func update_state_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, do_name : felt) -> ():
        states_internal.check_state_existence(name)
        let (actions) = states.read(name)
        let entry = actions.entry
        let exit = actions.exit
        let do = Action(name=do_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func update_state_exit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, exit_name : felt) -> ():
        states_internal.check_state_existence(name)
        let (actions) = states.read(name)
        let entry = actions.entry
        let do = actions.do
        let exit = Action(name=exit_name, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func remove_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        states_internal.check_state_existence(name)
        let entry = Action(name=0, external=0)
        let do = Action(name=0, external=0)
        let exit = Action(name=0, external=0)
        let state = State(entry=entry, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @view
    func get_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (state : State):
        states_internal.check_state_existence(name)
        let (state) = states.read(name)
        ret 
    end
end

namespace states_internal:
    func check_state_non_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (state) = states.read(name)
        with_attr error_message("This state already exists"):
            assert state.do.name = 0
        end
        ret
    end

    func check_state_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (state) = states.read(name)
        with_attr error_message("This state doesn't exist"):
            assert_not_zero(state.do.name)
        end
        ret
    end

    func check_init_not_final {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (final) = final_state.read()
        with_attr error_message("Initial and Final states can't be the same."):
            assert_not_equal(name, final)
        end
        ret
    end

    func check_final_not_init {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (init) = init_state.read()
        with_attr error_message("Initial and Final states can't be the same."):
            assert_not_equal(name, init)
        end
        ret
    end
end

namespace states_config:
    @external
    func set_init_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        states_internal.check_state_existence(name)
        states_internal.check_init_not_final(name)
        init_state.write(name)

        let (current) = current_state.read()
        if current == 0:
            set_curr_state(name)
        end
        ret 
    end

    @external
    func set_final_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        states_internal.check_state_existence(name)
        states_internal.check_final_not_init(name)
        final_state.write(name)
        ret 
    end

    @external
    func set_curr_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        states_internal.check_state_existence(name)
        current_state.write(name)        
        ret 
    end

    @view
    func get_init_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (init : State):
        let (name) = init_state.read()
        let (init) = states_storage.get_state(name)
        ret 
    end

    @view
    func get_final_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (final : State):
        let (name) = final_state.read()
        let (final) = states_storage.get_state(name)
        ret 
    end

    @view
    func get_curr_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (curr : State):
        let (name) = current_state.read()
        let (curr) = states_storage.get_state(name)
        ret 
    end
end

namespace get_actions:
    @view
    func get_current_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (do_action : Action):
        let (curr) = states_config.get_curr_state()
        return (curr.do)
    end

    @view
    func get_state_action_entry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (entry : Action):
        let (state) = states_storage.get_state(name)
        let entry = state.entry
        ret
    end

    @view
    func get_state_action_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (do_action : Action):
        let (state) = states_storage.get_state(name)
        let do_action = state.do
        ret
    end

    @view 
    func get_state_action_exit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (exit : Action):
        let (state) = states_storage.get_state(name)
        let exit = state.exit
        ret
    end

    @view
    func get_transition_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action) -> (trans_act : Action):
        states_internal.check_state_existence(from_name)
        states_internal.check_state_existence(to_name)
        let (trans) = transitions.read(from_name, to_name, event)
        return (trans.action)
    end
end

namespace transition_storage:
    @external
    func add_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action, trans_action_name : felt, condition : felt) -> ():
        states_internal.check_state_existence(from_name)
        states_internal.check_state_existence(to_name)
        
        let transition_action = Action(name=trans_action_name, external=0)
        let transition = Transition(transition_action, condition)
        transitions.write(from_name, to_name, event, transition)
        ret
    end

    #add
    #update
    #remove
    #get
end



#figure out conditions/guards
#refactor actions








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