// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";


/**
 * @title Helps to manage contract addres of chainlink price feeds for different blockchains
 * @author Gabriel Eguiguren
 * 
 * https://docs.chain.link/data-feeds/price-feeds/addresses?page=1&testnetPage=1
 * 
 */
contract HelperConfig is Script {

    struct NetworkConfig {
        address priceFeed;
        //vrf address , etc
    }

    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 4200e8;
    
    constructor() {
        if (block.chainid == 11155111){
            activeNetworkConfig = getSepholiaEthConfig();
        } else if (block.chainid == 1){
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }   
    }

    function getSepholiaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory network = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return network;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory network = NetworkConfig({priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return network;
    }

    // deploy a mock contract to Anvil locla blockchain
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        //checks if already exits
        if(activeNetworkConfig.priceFeed != address(0)){
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory network = NetworkConfig({priceFeed: address(mockV3Aggregator)});
        return network;
    }

}