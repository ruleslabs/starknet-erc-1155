#[starknet::contract]
mod SnakeERC1155Mock {
  use array::{ SpanSerde, ArrayTrait };
  use rules_utils::introspection::interface::ISRC5;

  //locals
  use rules_erc1155::erc1155::interface::{ IERC1155, IERC1155Metadata };
  use rules_erc1155::erc1155::erc1155::ERC1155;
  use rules_erc1155::erc1155::erc1155::ERC1155::InternalTrait as ERC1155InternalTrait;

  //
  // Storage
  //

  #[storage]
  struct Storage {}

  //
  // Constrcutor
  //

  #[constructor]
  fn constructor(ref self: ContractState, uri_: Span<felt252>, id: u256, amount: u256, data: Span<felt252>) {
    let mut erc1155_self = ERC1155::unsafe_new_contract_state();

    let caller = starknet::get_caller_address();

    erc1155_self.initializer(uri_);
    erc1155_self._mint(to: caller, :id, :amount, :data);
  }

  //
  // IERC1155 impl
  //

  #[external(v0)]
  impl IERC1155Impl of IERC1155<ContractState> {
    fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balance_of(:account, :id)
    }

    fn balance_of_batch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Span<u256> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balance_of_batch(:accounts, :ids)
    }

    fn is_approved_for_all(self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.is_approved_for_all(:account, :operator)
    }

    fn set_approval_for_all(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.set_approval_for_all(:operator, :approved);
    }

    fn safe_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safe_transfer_from(:from, :to, :id, :amount, :data);
    }

    fn safe_batch_transfer_from(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
    }
  }

  //
  // IERC1155 Metadata impl
  //

  #[external(v0)]
  impl IERC1155MetadataImpl of IERC1155Metadata<ContractState> {
    fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.uri(:token_id)
    }
  }

  //
  // ISRC5 impl
  //

  #[external(v0)]
  impl ISRC5Impl of ISRC5<ContractState> {
    fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.supports_interface(:interface_id)
    }
  }
}
