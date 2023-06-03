use starknet::testing;
use array::{ ArrayTrait, SpanTrait };
use traits::Into;
use zeroable::Zeroable;
use debug::{ PrintTrait, U32PrintImpl };
use integer::u256_from_felt252;
use rules_account::account::Account;

use rules_erc1155::introspection::erc165;
use rules_erc1155::erc1155;
use rules_erc1155::erc1155::ERC1155;
use rules_erc1155::utils::partial_eq::SpanPartialEq;

use rules_erc1155::tests::utils;
use rules_erc1155::tests::mocks::erc1155_receiver::{ ERC1155Receiver, ERC1155NonReceiver, SUCCESS, FAILURE };

fn URI() -> Span<felt252> {
  let mut uri = ArrayTrait::new();

  uri.append(111);
  uri.append(222);
  uri.append(333);

  uri.span()
}

fn TOKEN_ID() -> u256 {
  0xDEAD.into()
}

fn AMOUNT() -> u256 {
  0xFA11.into()
}

fn ZERO() -> starknet::ContractAddress {
  Zeroable::zero()
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

fn OTHER() -> starknet::ContractAddress {
  starknet::contract_address_const::<50>()
}

fn DATA(success: bool) -> Span<felt252> {
  let mut data = ArrayTrait::new();
  if success {
    data.append(SUCCESS);
  } else {
    data.append(FAILURE);
  }
  data.span()
}

//
// Setup
//

fn setup() -> starknet::ContractAddress {
  let owner = setup_receiver();

  ERC1155::initializer(URI());
  ERC1155::_mint(to: owner, id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));

  owner
}

fn setup_receiver() -> starknet::ContractAddress {
  utils::deploy(ERC1155Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn setup_account() -> starknet::ContractAddress {
  let mut calldata = ArrayTrait::new();
  let public_key: felt252 = 1234678;

  calldata.append(public_key);
  calldata.append(0); // guardian pub key

  utils::deploy(Account::TEST_CLASS_HASH, calldata)
}

//
// Initializers
//

#[test]
#[available_gas(20000000)]
fn test_constructor() {
  ERC1155::constructor(URI());

  assert(ERC1155::uri(TOKEN_ID()) == URI(), 'uri should be URI()');

  assert(ERC1155::balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

  assert(ERC1155::supports_interface(erc1155::interface::IERC1155_ID), 'Missing interface ID');
  assert(ERC1155::supports_interface(erc1155::interface::IERC1155_METADATA_ID), 'missing interface ID');
  assert(ERC1155::supports_interface(erc165::IERC165_ID), 'missing interface ID');

  assert(!ERC1155::supports_interface(erc165::INVALID_ID), 'invalid interface ID');
}

#[test]
#[available_gas(20000000)]
fn test_initialize() {
  ERC1155::initializer(URI());

  assert(ERC1155::uri(TOKEN_ID()) == URI(), 'uri should be URI()');

  assert(ERC1155::balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

  assert(ERC1155::supports_interface(erc1155::interface::IERC1155_ID), 'Missing interface ID');
  assert(ERC1155::supports_interface(erc1155::interface::IERC1155_METADATA_ID), 'missing interface ID');
  assert(ERC1155::supports_interface(erc165::IERC165_ID), 'missing interface ID');

  assert(!ERC1155::supports_interface(erc165::INVALID_ID), 'invalid interface ID');
}

//
// Balances
//

#[test]
#[available_gas(20000000)]
fn test_balance_of() {
  let owner = setup();
  assert(ERC1155::balance_of(account: owner, id: TOKEN_ID()) == AMOUNT(), 'Balance should be zero');
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_zero() {
  assert(ERC1155::balance_of(account: ZERO(), id: TOKEN_ID()) == 0.into(), 'Balance should be zero');
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_batch() {
  let mut accounts = ArrayTrait::<starknet::ContractAddress>::new();
  accounts.append(setup_receiver());
  accounts.append(setup_receiver());
  accounts.append(setup_receiver());

  let mut ids = ArrayTrait::<u256>::new();
  ids.append('id1'.into());
  ids.append('id2'.into());
  ids.append('id3'.into());

  let mut amounts = ArrayTrait::<u256>::new();
  amounts.append('amount1'.into());
  amounts.append('amount2'.into());
  amounts.append('amount3'.into());

  // Mint
  ERC1155::_mint(to: *accounts.at(0), id: *ids.at(0), amount: *amounts.at(0), data: DATA(true));
  ERC1155::_mint(to: *accounts.at(1), id: *ids.at(1), amount: *amounts.at(1), data: DATA(true));
  ERC1155::_mint(to: *accounts.at(2), id: *ids.at(2), amount: *amounts.at(2), data: DATA(true));

  assert(
    ERC1155::balance_of_batch(accounts: accounts.span(), ids: ids.span()).span() == amounts.span(),
    'Balances should be amounts'
  );
}

//
// URI
//

#[test]
#[available_gas(20000000)]
fn test_set_uri() {
  setup();

  let mut new_URI = ArrayTrait::new();
  new_URI.append('random');
  new_URI.append(0);
  new_URI.append('felt252');
  new_URI.append(0);
  new_URI.append('elements');
  new_URI.append('.');
  ERC1155::_set_URI(new_URI: new_URI.span());

  assert(new_URI.span() == ERC1155::uri(0.into()), 'uri should be new_URI');
}

#[test]
#[available_gas(20000000)]
fn test_set_empty_uri() {
  setup();

  let empty_uri = ArrayTrait::new().span();
  ERC1155::_set_URI(new_URI: empty_uri);

  assert(empty_uri == ERC1155::uri(0.into()), 'uri should be empty');
}

//
// Approval
//

#[test]
#[available_gas(20000000)]
fn test_is_approved_for_all() {
  let owner = setup();
  let operator = OPERATOR();
  let token_id = TOKEN_ID();

  assert(!ERC1155::is_approved_for_all(owner, operator), 'Should not be approved');

  testing::set_caller_address(owner);
  ERC1155::set_approval_for_all(operator, true);

  assert(ERC1155::is_approved_for_all(owner, operator), 'Should be approved');
}

#[test]
#[available_gas(2000000)]
fn test_set_approval_for_all() {
  testing::set_caller_address(OWNER());
  assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

  ERC1155::set_approval_for_all(OPERATOR(), true);
  assert(ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

  ERC1155::set_approval_for_all(OPERATOR(), false);
  assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Approval not revoked correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test_set_approval_for_all_owner_equal_operator_true() {
  testing::set_caller_address(OWNER());
  ERC1155::set_approval_for_all(OWNER(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test_set_approval_for_all_owner_equal_operator_false() {
  testing::set_caller_address(OWNER());
  ERC1155::set_approval_for_all(OWNER(), false);
}

#[test]
#[available_gas(2000000)]
fn test__set_approval_for_all() {
  assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

  ERC1155::_set_approval_for_all(OWNER(), OPERATOR(), true);
  assert(ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

  ERC1155::_set_approval_for_all(OWNER(), OPERATOR(), false);
  assert(!ERC1155::is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test__set_approval_for_all_owner_equal_operator_true() {
  ERC1155::_set_approval_for_all(OWNER(), OWNER(), true);
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test__set_approval_for_all_owner_equal_operator_false() {
  ERC1155::_set_approval_for_all(OWNER(), OWNER(), false);
}

//
// Mint
//

#[test]
#[available_gas(20000000)]
fn test_mint() {
  setup();

  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_mint(:recipient, :token_id);

  ERC1155::_mint(to: recipient, id: token_id, :amount, data: DATA(true));

  assert_state_after_mint(:recipient, :token_id, :amount);
}

//
// Helpers
//

fn assert_state_before_mint(recipient: starknet::ContractAddress, token_id: u256) {
  assert(ERC1155::balance_of(recipient, token_id) == 0.into(), 'Balance of recipient before');
}

fn assert_state_after_mint(recipient: starknet::ContractAddress, token_id: u256, amount: u256) {
  assert(ERC1155::balance_of(recipient, token_id) == amount, 'Balance of recipient after');
}
