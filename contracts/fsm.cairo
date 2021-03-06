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
    member entry : felt
    member do : felt
    member exit : felt
end

struct Transition:
    member action : felt
    member condition : felt # if 1, this transition is enabled. if 0, this transition is disabled.
end

################################################################################
# Storage Vars
################################################################################

@storage_var
func states (name : felt) -> (state : State):
end

@storage_var
func states_inc() -> (name : felt):
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

@storage_var
func actions(name : felt) -> (action : Action):
end

@storage_var
func actions_inc() -> (name : felt):
end

#event can be an external action (give a name, and external bool = 0), or entry/do/exit action, or a transition action
@storage_var
func transitions(from_name : felt, to_name : felt, event : felt) -> (transition : Transition):
end

################################################################################
# Functions
################################################################################
@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    states_inc.write(1)
    actions_inc.write(1)
    ret
end

namespace actions_storage:
    @external
    func add_internal_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt):
        let (curr) = actions_inc.read()
        assert_not_zero(name)
        actions.write(curr, Action(name, 0))
        actions_inc.write(curr + 1)
        ret
    end

    @external
    func add_external_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt):
        let (curr) = actions_inc.read()
        assert_not_zero(name)
        actions.write(curr, Action(name, 1))
        actions_inc.write(curr + 1)
        ret
    end

    @external
    func update_action_name {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, action_name : felt):
        internal_utils.check_action_existence(name)
        assert_not_zero(action_name)

        let (action) = actions.read(name)
        actions.write(name, Action(action_name, action.external))
        ret
    end

    @external
    func delete_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt):
        internal_utils.check_action_existence(name)
        actions.write(name, Action(0, 0))
        ret
    end

    @external
    func get_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (action : Action):
        let (action) = actions.read(name)
        ret
    end
end

namespace states_storage:
    @external
    func add_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(entry_name : felt, do_name : felt, exit_name : felt) -> ():
        alloc_locals
        let (local curr) = states_inc.read()

        internal_utils.check_action_existence(entry_name)
        internal_utils.check_action_existence(do_name)
        internal_utils.check_action_existence(exit_name)

        let state = State(entry=entry_name, do=do_name, exit=exit_name)
        states.write(curr, state)

        states_inc.write(curr + 1)
        ret
    end

    @external
    func update_state_entry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt) -> ():
        internal_utils.check_state_existence(name)
        internal_utils.check_action_existence(entry_name)

        let (actions) = states.read(name)
        let do = actions.do
        let exit = actions.exit

        let state = State(entry=entry_name, do=do, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func update_state_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, do_name : felt) -> ():
        internal_utils.check_state_existence(name)
        internal_utils.check_action_existence(do_name)

        let (actions) = states.read(name)
        let entry = actions.entry
        let exit = actions.exit

        let state = State(entry=entry, do=do_name, exit=exit)
        states.write(name, state)
        ret
    end

    @external
    func update_state_exit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, exit_name : felt) -> ():
        internal_utils.check_state_existence(name)
        internal_utils.check_action_existence(exit_name)
        
        let (actions) = states.read(name)
        let entry = actions.entry
        let do = actions.do

        let state = State(entry=entry, do=do, exit=exit_name)
        states.write(name, state)
        ret
    end

    @external
    func remove_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        internal_utils.check_state_existence(name)
        let state = State(entry=0, do=0, exit=0)
        states.write(name, state)
        ret
    end

    @view
    func get_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (state : State):
        internal_utils.check_state_existence(name)
        let (state) = states.read(name)
        ret 
    end
end

namespace internal_utils:
    func check_state_non_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (state) = states.read(name)
        let (do_action) = actions_storage.get_action(state.do)
        with_attr error_message("This state already exists"):
            assert do_action = 0
        end
        ret
    end

    func check_state_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (state) = states.read(name)
        with_attr error_message("This state doesn't exist"):
            assert_not_zero(state.do)
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

    func check_action_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (action) = actions.read(name)
        with_attr error_message("This action doesn't exist"):
            assert_not_zero(action.name)
        end
        ret
    end

    func check_action_is_internal {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        let (action) = actions.read(name)
        with_attr error_message("This action is external"):
            assert action.external = 0
        end
        ret
    end

    func check_transition_existence {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : felt):
        check_state_existence(from_name)
        check_state_existence(to_name)
        check_action_existence(event)
        let (trans) = transitions.read(from_name, to_name, event)
        with_attr error_message("This transition doesn't exist"):
            assert_not_zero(trans.action)
        end
        ret
    end

    func check_from_is_curr {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_state : felt):
        let (curr) = current_state.read()
        with_attr error_message("curr is not from_state"):
            assert curr = from_state
        end
        ret
    end
end

namespace states_config:
    @external
    func set_init_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        internal_utils.check_state_existence(name)
        internal_utils.check_init_not_final(name)
        init_state.write(name)

        let (current) = current_state.read()
        if current == 0:
            set_curr_state(name)
        end
        ret 
    end

    @external
    func set_final_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        internal_utils.check_state_existence(name)
        internal_utils.check_final_not_init(name)
        final_state.write(name)
        ret 
    end

    @external
    func set_curr_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> ():
        internal_utils.check_state_existence(name)
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
        let (do_action) = actions_storage.get_action(curr.do)
        ret
    end

    @view
    func get_state_action_entry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (entry : Action):
        let (state) = states_storage.get_state(name)
        let (entry) = actions_storage.get_action(state.entry)
        ret
    end

    @view
    func get_state_action_do {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (do_action : Action):
        let (state) = states_storage.get_state(name)
        let (do_action) = actions_storage.get_action(state.do)
        ret
    end

    @view 
    func get_state_action_exit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt) -> (exit : Action):
        let (state) = states_storage.get_state(name)
        let (exit) = actions_storage.get_action(state.exit)
        ret
    end

    @view
    func get_transition_action {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : felt) -> (trans_act : Action):
        internal_utils.check_transition_existence(from_name, to_name, event)
        let (trans) = transitions.read(from_name, to_name, event)
        let (trans_act) = actions_storage.get_action(trans.action)
        ret
    end
end

namespace transition_storage:
    @external
    func add_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : felt, trans_action : felt, condition : felt) -> ():
        internal_utils.check_state_existence(from_name)
        internal_utils.check_state_existence(to_name)
        internal_utils.check_action_existence(event)
        internal_utils.check_action_existence(trans_action)
        
        let transition = Transition(trans_action, condition)
        transitions.write(from_name, to_name, event, transition)
        ret
    end

    @external
    func remove_transaction {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : felt):
        internal_utils.check_transition_existence(from_name, to_name, event)
        let transition = Transition(0, 0) 
        transitions.write(from_name, to_name, event, transition)
        ret
    end
end

@external
func execute_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : felt) -> (entry : Action, transition : Action, exit : Action):
    internal_utils.check_transition_existence(from_name, to_name, event)
    let (curr) = states_config.get_curr_state()
    internal_utils.check_from_is_curr(from_name)
    
    let (exit) = get_actions.get_state_action_exit(from_name)
    let (transition) = get_actions.get_transition_action(from_name, to_name, event)
    let (entry) = get_actions.get_state_action_entry(to_name)

    states_config.set_curr_state(to_name)
    ret
end