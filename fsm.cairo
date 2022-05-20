%lang starknet

struct Condition:
end

struct Action:
    member name : felt
    member external : felt # if 1, this action is initiated by environment. if 0, this action is initiated by another agent.
end

struct State:
    member entry: Action
    member do : Action
    member exit: Action
end

struct Transition:
    member action : Action
    member condition : Condition
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
func transition(from_name : felt, to_name : felt, event : Action) -> (transition : Transition):
end


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