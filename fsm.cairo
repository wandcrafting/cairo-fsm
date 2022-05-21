%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal

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

@storage_var
func states(name : felt) -> (state : State):
end

@storage_var
func init_state() -> (name : felt): 
end

@storage_var
func final_state() -> (name : felt): 
end

#event can be an external action (give a name, and external bool = 0), or entry/do/exit action, or a transition action
@storage_var
func transitions(from_name : felt, to_name : felt, event : Action) -> (transition : Transition):
end

func add_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(name : felt, entry_name : felt, do_name : felt, exit_name : felt) -> ():
    let entry = Action(name=entry_name, external=0)
    let do = Action(name=do_name, external=0)
    let exit = Action(name=exit_name, external=0)
    let state = State(entry=entry, do=do, exit=exit)
    states.write(name, state)
    ret
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

func add_transition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(from_name : felt, to_name : felt, event : Action, trans_action_name : felt, condition : felt) -> ():
    #%TODO: check if state exists for from_name, to_name
    let transition_action = Action(name=trans_action_name, external=0)
    let transition = Transition(transition_action, condition)
    transitions.write(from_name, to_name, event, transition)
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



#func transition(from_name : felt, to_name : felt, event : Action) -> (transition : Transition):



    # transition(currentState, event) {
    #   const currentStateDefinition = stateMachineDefinition[currentState]
    #   const destinationTransition = currentStateDefinition.transitions[event]
    #   if (!destinationTransition) {
    #     return
    #   }
    #   const destinationState = destinationTransition.target
    #   const destinationStateDefinition =
    #     stateMachineDefinition[destinationState]

    #   destinationTransition.action()
    #   currentStateDefinition.actions.onExit()
    #   destinationStateDefinition.actions.onEnter()