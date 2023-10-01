use array::{ ArrayTrait, SpanPartialEq };
use starknet::testing;
use rules_utils::utils::serde::SerdeTraitExt;

// locals
use rules_erc1155::erc1155::interface::IERC1155_ID;

use super::mocks::erc1155_mocks::{ SnakeERC1155Mock, CamelERC1155Mock, SnakeERC1155PanicMock, CamelERC1155PanicMock };
use super::mocks::erc1155_receiver_mocks::{ SnakeERC1155ReceiverMock, SUCCESS, FAILURE };
use super::mocks::non_implementing_mock::NonImplementingMock;

use super::utils;

// Dispatchers
use rules_erc1155::erc1155::dual_erc1155::{ DualCaseERC1155, DualCaseERC1155Trait, };
use rules_erc1155::erc1155::interface::{
  IERC1155Dispatcher,
  IERC1155DispatcherTrait,
  IERC1155CamelOnlyDispatcher,
  IERC1155CamelOnlyDispatcherTrait,
};

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

fn URI() -> Span<felt252> {
  array![333].span()
}

fn OWNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<10>()
}

fn RECIPIENT() -> starknet::ContractAddress {
  starknet::contract_address_const::<20>()
}

fn SPENDER() -> starknet::ContractAddress {
  starknet::contract_address_const::<30>()
}

fn OPERATOR() -> starknet::ContractAddress {
  starknet::contract_address_const::<40>()
}

fn DATA(success: bool) -> Span<felt252> {
  if success {
    array![SUCCESS].span()
  } else {
    array![FAILURE].span()
  }
}

fn ADDRESSES(address: starknet::ContractAddress) -> Span<starknet::ContractAddress> {
  array![address].span()
}

//
// Setup
//

fn setup_snake(receiver: starknet::ContractAddress) -> (DualCaseERC1155, IERC1155Dispatcher) {
  let mut calldata = array![];
  calldata.append_serde(URI());
  calldata.append_serde(TOKEN_ID);
  calldata.append_serde(AMOUNT);
  calldata.append_serde(DATA(true));

  testing::set_contract_address(receiver);
  let contract_address = utils::deploy(SnakeERC1155Mock::TEST_CLASS_HASH, calldata);

  (DualCaseERC1155 { contract_address }, IERC1155Dispatcher { contract_address })
}

fn setup_camel(receiver: starknet::ContractAddress) -> (DualCaseERC1155, IERC1155CamelOnlyDispatcher) {
  let mut calldata = array![];
  calldata.append_serde(URI());
  calldata.append_serde(TOKEN_ID);
  calldata.append_serde(AMOUNT);
  calldata.append_serde(DATA(true));

  testing::set_contract_address(receiver);
  let contract_address = utils::deploy(CamelERC1155Mock::TEST_CLASS_HASH, calldata);

  (DualCaseERC1155 { contract_address }, IERC1155CamelOnlyDispatcher { contract_address })
}

fn setup_non_erc1155() -> DualCaseERC1155 {
  let contract_address = utils::deploy(NonImplementingMock::TEST_CLASS_HASH, calldata: array![]);

  DualCaseERC1155 { contract_address }
}

fn setup_erc1155_panic() -> (DualCaseERC1155, DualCaseERC1155) {
  let snake_contract_address = utils::deploy(SnakeERC1155PanicMock::TEST_CLASS_HASH, array![]);
  let camel_contract_address = utils::deploy(CamelERC1155PanicMock::TEST_CLASS_HASH, array![]);

  (
    DualCaseERC1155 { contract_address: snake_contract_address },
    DualCaseERC1155 { contract_address: camel_contract_address }
  )
}

fn setup_receiver() -> starknet::ContractAddress {
  utils::deploy(SnakeERC1155ReceiverMock::TEST_CLASS_HASH, array![])
}

//
// Case agnostic methods
//

#[test]
#[available_gas(20000000)]
fn test_dual_uri() {
  let receiver = setup_receiver();
  let (snake_dispatcher, _) = setup_snake(:receiver);
  let (camel_dispatcher, _) = setup_camel(:receiver);

  assert(snake_dispatcher.uri(token_id: TOKEN_ID) == URI(), 'Should return uri');
  // assert(camel_dispatcher.uri(token_id: TOKEN_ID) == URI(), 'Should return uri');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_uri() {
  let dispatcher = setup_non_erc1155();

  dispatcher.uri(token_id: TOKEN_ID);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_uri_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.uri(token_id: TOKEN_ID);
}

//
// snake_case target
//

// balance_of

#[test]
#[available_gas(20000000)]
fn test_dual_balance_of() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_snake(:receiver);

  assert(dispatcher.balance_of(account: receiver, id: TOKEN_ID) == AMOUNT, 'Should return balance');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_balance_of() {
  let dispatcher = setup_non_erc1155();

  dispatcher.balance_of(account: OWNER(), id: TOKEN_ID);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_balance_of_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.balance_of(account: OWNER(), id: TOKEN_ID);
}

// balance_of_batch

#[test]
#[available_gas(20000000)]
fn test_dual_balance_of_batch() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_snake(:receiver);

  assert(
    dispatcher.balance_of_batch(accounts: ADDRESSES(receiver), ids: TOKEN_IDS()) == AMOUNTS(),
    'Should return balance'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_balance_of_batch() {
  let dispatcher = setup_non_erc1155();

  dispatcher.balance_of_batch(accounts: ADDRESSES(OWNER()), ids: TOKEN_IDS());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_balance_of_batch_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.balance_of_batch(accounts: ADDRESSES(OWNER()), ids: TOKEN_IDS());
}

// is_approved_for_all

#[test]
#[available_gas(20000000)]
fn test_dual_is_approved_for_all() {
  let receiver = setup_receiver();
  let (dispatcher, target) = setup_snake(:receiver);

  testing::set_contract_address(OWNER());
  target.set_approval_for_all(OPERATOR(), true);
  assert(dispatcher.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_is_approved_for_all() {
  let dispatcher = setup_non_erc1155();

  dispatcher.is_approved_for_all(OWNER(), OPERATOR());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_is_approved_for_all_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.is_approved_for_all(OWNER(), OPERATOR());
}

// set_approval_for_all

#[test]
#[available_gas(20000000)]
fn test_dual_set_approval_for_all() {
  let receiver = setup_receiver();
  let (dispatcher, target) = setup_snake(:receiver);

  testing::set_contract_address(OWNER());
  dispatcher.set_approval_for_all(OPERATOR(), true);
  assert(target.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_set_approval_for_all() {
  let dispatcher = setup_non_erc1155();

  dispatcher.set_approval_for_all(OPERATOR(), true);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_set_approval_for_all_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.set_approval_for_all(OPERATOR(), true);
}

// safe_transfer_from

#[test]
#[available_gas(20000000)]
fn test_dual_safe_transfer_from() {
  let receiver = setup_receiver();
  let other_receiver = setup_receiver();
  let (dispatcher, target) = setup_snake(:receiver);

  testing::set_contract_address(receiver);
  dispatcher.safe_transfer_from(from: receiver, to: other_receiver, id: TOKEN_ID, amount: AMOUNT, data: DATA(true));

  assert(target.balance_of(account: receiver, id: TOKEN_ID) == 0, 'Should transfer token');
  assert(target.balance_of(account: other_receiver, id: TOKEN_ID) == AMOUNT, 'Should transfer token');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_safe_transfer_from() {
  let dispatcher = setup_non_erc1155();

  dispatcher.safe_transfer_from(OWNER(), RECIPIENT(), TOKEN_ID, AMOUNT, DATA(true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_safe_transfer_from_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.safe_transfer_from(OWNER(), RECIPIENT(), TOKEN_ID, AMOUNT, DATA(true));
}

// safe_batch_transfer_from

#[test]
#[available_gas(20000000)]
fn test_dual_safe_batch_transfer_from() {
  let receiver = setup_receiver();
  let other_receiver = setup_receiver();
  let (dispatcher, target) = setup_snake(:receiver);

  testing::set_contract_address(receiver);
  dispatcher.safe_batch_transfer_from(
    from: receiver,
    to: other_receiver,
    ids: TOKEN_IDS(),
    amounts: AMOUNTS(),
    data: DATA(true)
  );

  assert(target.balance_of(account: receiver, id: TOKEN_ID) == 0, 'Should transfer token');
  assert(target.balance_of(account: other_receiver, id: TOKEN_ID) == AMOUNT, 'Should transfer token');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_safe_batch_transfer_from() {
  let dispatcher = setup_non_erc1155();

  dispatcher.safe_batch_transfer_from(OWNER(), RECIPIENT(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_safe_batch_transfer_from_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.safe_batch_transfer_from(OWNER(), RECIPIENT(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}

// supports_interface

#[test]
#[available_gas(20000000)]
fn test_dual_supports_interface() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_snake(:receiver);

  assert(dispatcher.supports_interface(IERC1155_ID), 'Should support own interface');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_dual_no_supports_interface() {
  let dispatcher = setup_non_erc1155();

  dispatcher.supports_interface(IERC1155_ID);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_supports_interface_exists_and_panics() {
  let (dispatcher, _) = setup_erc1155_panic();

  dispatcher.supports_interface(IERC1155_ID);
}

//
// camelCase target
//

// balanceOf

#[test]
#[available_gas(20000000)]
fn test_dual_balanceOf() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_camel(:receiver);

  assert(dispatcher.balance_of(account: receiver, id: TOKEN_ID) == AMOUNT, 'Should return balance');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_balanceOf_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.balance_of(account: OWNER(), id: TOKEN_ID);
}

// balanceOfBatch

#[test]
#[available_gas(20000000)]
fn test_dual_balanceOfBatch() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_camel(:receiver);

  assert(
    dispatcher.balance_of_batch(accounts: ADDRESSES(receiver), ids: TOKEN_IDS()) == AMOUNTS(),
    'Should return balances'
  );
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_balanceOfBatch_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.balance_of_batch(accounts: ADDRESSES(OWNER()), ids: TOKEN_IDS());
}

// isApprovedForAll

#[test]
#[available_gas(20000000)]
fn test_dual_isApprovedForAll() {
  let receiver = setup_receiver();
  let (dispatcher, target) = setup_camel(:receiver);

  testing::set_contract_address(OWNER());
  target.setApprovalForAll(OPERATOR(), true);
  assert(dispatcher.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_isApprovedForAll_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.is_approved_for_all(OWNER(), OPERATOR());
}

// setApprovalForAll

#[test]
#[available_gas(20000000)]
fn test_dual_setApprovalForAll() {
  let receiver = setup_receiver();
  let (dispatcher, target) = setup_camel(:receiver);

  testing::set_contract_address(OWNER());
  dispatcher.set_approval_for_all(OPERATOR(), true);
  assert(target.isApprovedForAll(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_setApprovalForAll_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.set_approval_for_all(OPERATOR(), true);
}

// safeTransferFrom

#[test]
#[available_gas(20000000)]
fn test_dual_safeTransferFrom() {
  let receiver = setup_receiver();
  let other_receiver = setup_receiver();
  let (dispatcher, target) = setup_camel(:receiver);

  testing::set_contract_address(receiver);
  dispatcher.safe_transfer_from(from: receiver, to: other_receiver, id: TOKEN_ID, amount: AMOUNT, data: DATA(true));

  assert(target.balanceOf(account: receiver, id: TOKEN_ID) == 0, 'Should transfer token');
  assert(target.balanceOf(account: other_receiver, id: TOKEN_ID) == AMOUNT, 'Should transfer token');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_safeTransferFrom_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.safe_transfer_from(OWNER(), RECIPIENT(), TOKEN_ID, AMOUNT, DATA(true));
}

// safeBatchTransferFrom

#[test]
#[available_gas(20000000)]
fn test_dual_safeBatchTransferFrom() {
  let receiver = setup_receiver();
  let other_receiver = setup_receiver();
  let (dispatcher, target) = setup_camel(:receiver);

  testing::set_contract_address(receiver);
  dispatcher.safe_batch_transfer_from(
    from: receiver,
    to: other_receiver,
    ids: TOKEN_IDS(),
    amounts: AMOUNTS(),
    data: DATA(true)
  );

  assert(target.balanceOf(account: receiver, id: TOKEN_ID) == 0, 'Should transfer token');
  assert(target.balanceOf(account: other_receiver, id: TOKEN_ID) == AMOUNT, 'Should transfer token');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_safeBatchTransferFrom_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.safe_batch_transfer_from(OWNER(), RECIPIENT(), TOKEN_IDS(), AMOUNTS(), DATA(true));
}

// supportsInterface

#[test]
#[available_gas(20000000)]
fn test_dual_supportsInterface() {
  let receiver = setup_receiver();
  let (dispatcher, _) = setup_camel(:receiver);

  assert(dispatcher.supports_interface(IERC1155_ID), 'Should support own interface');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('Some error', 'ENTRYPOINT_FAILED', ))]
fn test_dual_supportsInterface_exists_and_panics() {
  let (_, dispatcher) = setup_erc1155_panic();

  dispatcher.supports_interface(IERC1155_ID);
}
