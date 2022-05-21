import pytest
import os
from starkware.starknet.testing.starknet import Starknet


@pytest.mark.asyncio
async def test_fsm():
    #starknet = await Starknet.empty()
    print()

   # contract = await starknet.deploy('fsm.cairo')
    print(f'> fsm.cairo deployed.')

    # await contract.add_state(name="A", entry_name="entry_a", do_name="do_a" ,exit_name="exit_a").invoke()
    # await contract.add_state(name="B", entry_name="entry_b", do_name="do_b" ,exit_name="exit_b").invoke()

    # check = await contract.state.read("A")
    # assert(check != 0)
   