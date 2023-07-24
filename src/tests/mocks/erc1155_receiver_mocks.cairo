mod snake_erc1155_receiver_mock;
use snake_erc1155_receiver_mock::SnakeERC1155ReceiverMock;

mod camel_erc1155_receiver_mock;
use camel_erc1155_receiver_mock::CamelERC1155ReceiverMock;

mod erc1155_receiver_panic_mocks;
use erc1155_receiver_panic_mocks::{ SnakeERC1155ReceiverPanicMock, CamelERC1155ReceiverPanicMock };

const SUCCESS: felt252 = 'SUCCESS';
const FAILURE: felt252 = 'FAILURE';

#[starknet::contract]
mod ERC1155NonReceiver {
  #[storage]
  struct Storage { }
}
