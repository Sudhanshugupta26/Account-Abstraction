// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "../lib/account-abstraction/contracts/core/EntryPoint.sol";

contract Helper is Script {
    error Helper__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;
    address constant BURNER_WALLET = 0x2f58bb8780191e71B538834FfA2329b8Cbb533Af;
    // address constant FOUNDRY_DEFAULT_WALLET =
    //     0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38; //Fetched from Base.sol in forge-std
    address constant ANVIL_DEFAULT_WALLET =
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert Helper__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, // EntryPoint contract address for ETH Sepolia
                account: 0x2f58bb8780191e71B538834FfA2329b8Cbb533Af
            });
    }

    function getZkSyncSepoliaConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                entryPoint: address(0), // Since zksync have native account abstraction.
                account: BURNER_WALLET
            });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        //deploy a mock entry point contract.
        vm.startBroadcast(ANVIL_DEFAULT_WALLET);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({
            entryPoint: address(entryPoint),
            account: ANVIL_DEFAULT_WALLET
        });

        return localNetworkConfig;
    }
}
