#[starknet::contract]
mod CamelERC1155Mock {
  use array::{ ArrayTrait, SpanSerde };
  use rules_utils::introspection::interface::ISRC5Camel;

  //locals
  use rules_erc1155::erc1155::interface::{ IERC1155, IERC1155Camel, IERC1155Metadata };
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
  // IERC1155 Camel impl
  //

  #[external(v0)]
  impl IERC1155CamelImpl of IERC1155Camel<ContractState> {
    fn balanceOf(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balanceOf(:account, :id)
    }

    fn balanceOfBatch(
      self: @ContractState,
      accounts: Span<starknet::ContractAddress>,
      ids: Span<u256>
    ) -> Span<u256> {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.balanceOfBatch(:accounts, :ids)
    }

    fn isApprovedForAll(self: @ContractState,
      account: starknet::ContractAddress,
      operator: starknet::ContractAddress
    ) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.isApprovedForAll(:account, :operator)
    }

    fn setApprovalForAll(ref self: ContractState, operator: starknet::ContractAddress, approved: bool) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.setApprovalForAll(:operator, :approved);
    }

    fn safeTransferFrom(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      id: u256,
      amount: u256,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safeTransferFrom(:from, :to, :id, :amount, :data);
    }

    fn safeBatchTransferFrom(
      ref self: ContractState,
      from: starknet::ContractAddress,
      to: starknet::ContractAddress,
      ids: Span<u256>,
      amounts: Span<u256>,
      data: Span<felt252>
    ) {
      let mut erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.safeBatchTransferFrom(:from, :to, :ids, :amounts, :data);
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
  // ISRC5 Camel impl
  //

  #[external(v0)]
  impl ISRC5CamelImpl of ISRC5Camel<ContractState> {
    fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
      let erc1155_self = ERC1155::unsafe_new_contract_state();

      erc1155_self.supportsInterface(:interfaceId)
    }
  }
}
