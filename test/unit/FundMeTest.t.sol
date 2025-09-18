// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    // setup is executed every time for every test Function
    function setUp() external {
        //addeed to avoid differences of deplox ex: constructor params
        DeployFundMe deployed = new DeployFundMe();
        fundMe = deployed.run();

        // adds founds for this created user address
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // as fork-test we copy the data from the test net:
    // forge test --mt testPriceFeedVersionIsAccurate -vvv --fork-url $SEPOLIA_RPC_URL
    function testPriceFeedVersionIsAccurate() public {
        if (block.chainid == 11155111) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 6);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        {
            //sending 0ETH
            fundMe.fund(); 
        }
    }

    function testFundUpdatesBalanceAndStructures() public {
        vm.prank(USER); //orverrides the owner and set the address for the next TXs
        fundMe.fund{value: SEND_VALUE}(); //the value is sent in TXs value

        uint256 amountFounded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFounded, SEND_VALUE);
    }

    function testAddsFounderToArrayOfFounders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address founder = fundMe.getFunders(0);
        assertEq(founder, USER);
    }

    // avoids code duplication
    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // use the modifier
    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        {
            fundMe.withdraw(); // This will revert because msg.sender is the owner, not USER 
        }
    }

    function testWithDrawWithSingleOwner() public funded{
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;
        
        assertEq(endingContractBalance, 0);
        assertEq(startingContractBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithDrawWithMultipleOwners() public funded{
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // address are uint160 numbers
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            // hoax is equivalent to vm.prank and vm.deal in a single instruction
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner()); // another way to prank
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        //Assert
        assert(endingContractBalance == 0);
        assert(startingContractBalance + startingOwnerBalance == endingOwnerBalance);
    }

}