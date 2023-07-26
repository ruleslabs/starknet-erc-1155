use array::ArrayTrait;

// locals
use super::mocks::erc1155_receiver_mocks::{
  SUCCESS,
  FAILURE,
  SnakeERC1155ReceiverMock,
  CamelERC1155ReceiverMock,
  SnakeERC1155ReceiverPanicMock,
  CamelERC1155ReceiverPanicMock,
};
use super::mocks::non_implementing_mock::NonImplementingMock;

use rules_erc1155::erc1155::interface::{ ON_ERC1155_RECEIVED_SELECTOR, ON_ERC1155_BATCH_RECEIVED_SELECTOR };

use super::utils;

// Dispatchers
use rules_erc1155::erc1155::interface::{
  IERC1155ReceiverDispatcher,
  IERC1155ReceiverDispatcherTrait,
  IERC1155ReceiverCamelDispatcher,
  IERC1155ReceiverCamelDispatcherTrait,
};
use rules_erc1155::erc1155::dual_erc1155_receiver::{ DualCaseERC1155Receiver, DualCaseERC1155ReceiverTrait };

//
// Constants
//

const TOKEN_ID: u256 = 7;
const AMOUNT: u256 = 7;

fn TOKEN_IDS() -> Span<u256> {
  array![TOKEN_ID].span()
}

fn AMOUNTS() -> Span<u256> {
  array![AMOUNT].span()
}

fn DATA(success: bool) -> Span<felt252> {
  if success {
    array![SUCCESS].span()
  } else {
    array![FAILURE].span()
  }
}

fn OWNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<10>()
}

fn OPERATOR() -> starknet::ContractAddress {
  starknet::contract_address_const::<20>()
}

//
// Setup
//

fn setup_snake_receiver() -> (DualCaseERC1155Receiver, IERC1155ReceiverDispatcher) {
  let contract_address = utils::deploy(SnakeERC1155ReceiverMock::TEST_CLASS_HASH, calldata: array![]);

  (DualCaseERC1155Receiver { contract_address }, IERC1155ReceiverDispatcher { contract_address })
}

fn setup_camel_receiver() -> (DualCaseERC1155Receiver, IERC1155ReceiverCamelDispatcher) {
  let contract_address = utils::deploy(CamelERC1155ReceiverMock::TEST_CLASS_HASH, calldata: array![]);

  (DualCaseERC1155Receiver { contract_address }, IERC1155ReceiverCamelDispatcher { contract_address })
}

fn setup_non_erc1155_receiver() -> DualCaseERC1155Receiver {
  let contract_address = utils::deploy(NonImplementingMock::TEST_CLASS_HASH, calldata: array![]);

  DualCaseERC1155Receiver { contract_address }
}

fn setup_erc1155_receiver_panic() -> (DualCaseERC1155Receiver, DualCaseERC1155Receiver) {
  let snake_contract_address = utils::deploy(
    SnakeERC1155ReceiverPanicMock::TEST_CLASS_HASH,
    calldata: array![]
  );
  let camel_contract_address = utils::deploy(
    CamelERC1155ReceiverPanicMock::TEST_CLASS_HASH,
    calldata: array![]
  );

  (
    DualCaseERC1155Receiver { contract_address: snake_contract_address },
    DualCaseERC1155Receiver { contract_address: camel_contract_address }
  )
}

//
// snake_case target
//

#[test]
#[available_gas(20000000)]
fn test_dual_on_erc1155_received() {
  let (dispatcher, _) = setup_snake_receiver();

  assert(
    dispatcher.on_erc1155_received(OPERATOR(), OWNER(), TOKEN_ID, AMOUNT, DATA(true)) == ON_ERC1155_RECEIVED_SELECTOR,
    'Should return selector id'
  );
}

#[test]
#[available_gas(20000000)]
fn test_dual_on_erc1155_batch_received() {
  let (dispatcher, _) = setup_snake_receiver();

  assert(
    dispatcher.on_erc1155_batch_received(
      OPERATOR(),
      OWNER(),
      TOKEN_IDS(),
      AMOUNTS(),
      DATA(true)
    ) == ON_ERC1155_BATCH_RECEIVED_SELECTOR,
    'Should return selector id'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_on_erc1155_received_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_receiver_panic();

  dispatcher.on_erc1155_received(OPERATOR(), OWNER(), TOKEN_ID, AMOUNT, DATA(true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_on_erc1155_batch_received_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_receiver_panic();

  dispatcher.on_erc1155_batch_received(OPERATOR(), OWNER(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}

//
// camelCase target
//

#[test]
#[available_gas(20000000)]
fn test_dual_onERC1155Received() {
  let (dispatcher, _) = setup_camel_receiver();

  assert(
    dispatcher.on_erc1155_received(OPERATOR(), OWNER(), TOKEN_ID, AMOUNT, DATA(true)) == ON_ERC1155_RECEIVED_SELECTOR,
    'Should return selector id'
  );
}

#[test]
#[available_gas(20000000)]
fn test_dual_onERC1155BatchReceived() {
  let (dispatcher, _) = setup_camel_receiver();

  assert(
    dispatcher.on_erc1155_batch_received(
      OPERATOR(),
      OWNER(),
      TOKEN_IDS(),
      AMOUNTS(),
      DATA(true)
    ) == ON_ERC1155_BATCH_RECEIVED_SELECTOR,
    'Should return selector id'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_onERC1155Received_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_receiver_panic();

  dispatcher.on_erc1155_received(OPERATOR(), OWNER(), TOKEN_ID, AMOUNT, DATA(true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_onERC1155BatchReceived_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_receiver_panic();

  dispatcher.on_erc1155_batch_received(OPERATOR(), OWNER(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}

//
// non ERC1155 receiver
//

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_on_erc1155_received() {
  let dispatcher = setup_non_erc1155_receiver();

  dispatcher.on_erc1155_received(OPERATOR(), OWNER(), TOKEN_ID, AMOUNT, DATA(true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_on_erc1155_batch_received() {
  let dispatcher = setup_non_erc1155_receiver();

  dispatcher.on_erc1155_batch_received(OPERATOR(), OWNER(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}
