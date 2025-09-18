// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    
    function run() external returns (FundMe) {
        // before startBroadcast not a real TXs
        HelperConfig helperConfig = new HelperConfig();
        // select the address acording to block.chainid
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig();
        
        // startBroadcast transaction gas spender
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);  
        vm.stopBroadcast();
        return fundMe;
    }
}
