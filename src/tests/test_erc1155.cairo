use starknet::testing;
use array::ArrayTrait;
use traits::Into;
use zeroable::Zeroable;
use rules_account::account::Account;

use rules_erc1155::introspection::erc165;
use rules_erc1155::erc1155;
use rules_erc1155::erc1155::ERC1155;

use rules_erc1155::tests::utils;
use rules_erc1155::tests::mocks::erc1155_receiver::{ ERC1155Receiver, ERC1155NonReceiver, SUCCESS, FAILURE };

fn URI() -> Array<felt252> {
  let mut uri = ArrayTrait::<felt252>::new();

  uri.append(111);
  uri.append(222);
  uri.append(333);

  uri
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

fn setup() {
  ERC1155::initializer(URI());
  ERC1155::_mint(to: OWNER(), id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));
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
